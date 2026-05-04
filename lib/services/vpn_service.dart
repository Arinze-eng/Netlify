import 'dart:async';
import 'dart:convert';

import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'proxy_payload.dart';

/// VPN/Proxy engine wrapper.
///
/// Default path uses **V2Ray core** via `flutter_v2ray`.
/// Sing-box is kept as a fallback and to avoid touching core build setup.
class VpnService {
  static const String prefsProxyKey = 'proxy_uri';
  static const String prefsVpnDisabledKey = 'vpn_disabled';
  static const String prefsVpnConfigTimestampKey = 'vpn_config_timestamp';

  // Built-in fallback config (used ONLY when no saved config and offline)
  static const String defaultProxyUri =
      'vless://a6f1755f-0140-4bea-8727-0db1bed7c4df@172.67.187.6:443?allowInsecure=1&encryption=none&host=juzi.qea.ccwu.cc&path=%2F&security=tls&sni=juzi.qea.ccwu.cc&type=ws#vless-SG';

  static Future<bool> isVpnDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsVpnDisabledKey) ?? false;
  }

  static Future<void> setVpnDisabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsVpnDisabledKey, v);
  }

  /// Load proxy URI: returns saved local config, or falls back to default.
  /// The saved config is updated from Supabase on every app open (when online).
  static Future<String> loadProxyUri() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(prefsProxyKey) ?? '').trim();
    return saved.isNotEmpty ? saved : defaultProxyUri;
  }

  static Future<void> saveProxyUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsProxyKey, uri.trim());
    await prefs.setString(prefsVpnConfigTimestampKey, DateTime.now().toUtc().toIso8601String());
  }

  /// Fetch the latest VPN config from Supabase and save it locally.
  /// This is called on app startup so the config is always up-to-date.
  /// If offline or fetch fails, the previously saved config is kept.
  static Future<String> fetchAndSaveRemoteConfig() async {
    try {
      final client = Supabase.instance.client;
      final res = await client.rpc('get_vpn_config').timeout(const Duration(seconds: 10));
      if (res == null) return await loadProxyUri();

      final list = (res as List);
      if (list.isEmpty) return await loadProxyUri();

      final row = Map<String, dynamic>.from(list.first as Map);
      // Prefer v2ray_share_link, fall back to share_link
      final link = (row['v2ray_share_link'] ?? row['share_link'] ?? '').toString().trim();

      if (link.isNotEmpty) {
        // Validate it's a proper vless/vmess link before saving
        if (link.startsWith('vless://') || link.startsWith('vmess://')) {
          await saveProxyUri(link);
          return link;
        }
      }
    } catch (_) {
      // Offline or error — use existing saved config (non-blocking)
    }

    return await loadProxyUri();
  }

  /// Check if the local config is stale (older than 1 hour) and needs refresh.
  static Future<bool> isConfigStale() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(prefsVpnConfigTimestampKey);
    if (ts == null) return true; // Never fetched
    final lastFetch = DateTime.tryParse(ts);
    if (lastFetch == null) return true;
    return DateTime.now().toUtc().difference(lastFetch).inHours >= 1;
  }

  /// Set false if you want to force old sing-box behavior.
  final bool preferV2Ray;

  // ----- V2Ray -----
  FlutterV2ray? _v2ray;
  bool _v2rayInitialized = false;
  final _statusCtrl = StreamController<Map<dynamic, dynamic>>.broadcast();


  VpnService({this.preferV2Ray = true}) {
    if (preferV2Ray) {
      _v2ray = FlutterV2ray(onStatusChanged: (status) {
        // Normalize to strings so UI logic is stable across plugin versions.
        _statusCtrl.add({
          'engine': 'v2ray',
          'state': status.state.toString(),
          'duration': status.duration,
        });
      });
    }
  }

  // ---- Streams expected by UI (traffic/log/status) ----

  /// V2Ray plugin does not expose traffic stats; we expose status updates.
  Stream<Map<dynamic, dynamic>> get trafficStream => _statusCtrl.stream;

  /// V2Ray plugin does not expose logs as a stream.
  Stream<Map<dynamic, dynamic>> get logStream => const Stream.empty();

  /// Status updates.
  Stream<Map<dynamic, dynamic>> get vpnStatus => _statusCtrl.stream;

  Future<List<dynamic>> getLogs() async {
    final v2 = _v2ray;
    if (v2 == null) return ['V2Ray engine not initialized'];

    final lines = <dynamic>[];
    try {
      lines.add('engine=v2ray');
      lines.add('coreVersion=${await v2.getCoreVersion()}');
      try {
        final delay = await v2.getConnectedServerDelay();
        lines.add('connectedDelayMs=$delay');
      } catch (_) {
        // ignore if not connected
      }
    } catch (e) {
      lines.add('log_error=$e');
    }
    return lines;
  }

  Future<void> clearLogs() async {
    // no-op for v2ray
  }

  Future<void> _ensureV2RayInitialized() async {
    final v2 = _v2ray;
    if (v2 == null) return;
    if (_v2rayInitialized) return;

    await v2.initializeV2Ray();
    _v2rayInitialized = true;
  }

  /// Starts VPN using a V2Ray share link (vless:// or vmess://).
  ///
  /// NOTE: [payload] is kept for compatibility and potential future use.
  Future<void> startVpn({
    required String shareLink,
    List<String>? blockedApps,
    ProxyPayload? payload,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final v2 = _v2ray;
    if (v2 == null) {
      throw StateError('V2Ray engine is not available');
    }

    await _ensureV2RayInitialized().timeout(timeout);

    // Ensure a clean state before starting (prevents stuck CONNECTING if a previous
    // instance was started earlier in the app lifecycle).
    try {
      await v2.stopV2Ray();
    } catch (_) {
      // ignore
    }

    final granted = await v2.requestPermission().timeout(timeout);
    if (!granted) {
      throw Exception('VPN permission not granted');
    }

    final parsed = FlutterV2ray.parseFromURL(shareLink);
    final remark = (parsed.remark.isNotEmpty) ? parsed.remark : 'Proxy';
    final config = parsed.getFullConfiguration();

    // Wait for CONNECTED state. Without this, the UI can show "VPN ON"
    // even when the native service immediately fails to start.
    final completer = Completer<void>();
    // Emit a local "connecting" event so UI can immediately reflect progress.
    _statusCtrl.add({'engine': 'v2ray', 'state': 'connecting', 'duration': 0});
    late final StreamSubscription sub;
    sub = _statusCtrl.stream.listen((e) {
      if (e is! Map) return;
      final state = (e['state'] ?? '').toString().toLowerCase();
      if (state.contains('connected')) {
        if (!completer.isCompleted) completer.complete();
      }
      if (state.contains('disconnected') || state.contains('stopped') || state.contains('error')) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('V2Ray state=$state'));
        }
      }
    });

    try {
      await v2
          .startV2Ray(
            remark: remark,
            config: config,
            blockedApps: blockedApps,
            bypassSubnets: null,
            // proxyOnly=false enables VPN mode (system VPN profile + key icon).
            proxyOnly: false,
          )
          .timeout(timeout);

      // Some devices report the status slightly after startV2Ray returns.
      await completer.future.timeout(const Duration(seconds: 12));

      // Best-effort sanity check: if we can query server delay, we treat it as connected.
      // Some devices may not emit CONNECTED state reliably.
      try {
        await v2.getConnectedServerDelay();
      } catch (_) {
        // ignore
      }
    } finally {
      await sub.cancel();
    }
  }

  Future<void> stopVpn() async {
    await _v2ray?.stopV2Ray();
  }

  void dispose() {
    _statusCtrl.close();
  }
}
