import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_apps/device_apps.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vpn_service.dart';
import 'supabase_service.dart';

/// App-wide VPN session manager ("Offline Mode VPN(60MB)").
///
/// Goals:
/// - Start VPN once when app opens (offline mode pathway)
/// - VPN auto-starts even if user is NOT signed in
/// - Avoid double-start races across Login/Signup/Chat screens
/// - Keep VPN running across auth transitions
/// - VPN auto-disconnects when user leaves the app, reconnects on resume
/// - Respect 5-day trial: after trial expires, VPN will NOT start at all
///   until the user pays or admin activates premium
/// - Fetch latest VPN config from Supabase on startup and save locally
/// - If admin updates VPN config, it persists locally and works offline
/// - Once VPN has started at app open, if user manually turns it off,
///   it will NOT auto-restart. Only lifecycle-based reconnects are allowed.
class VpnManager extends ChangeNotifier {
  VpnManager._() {
    _statusSub = _service.vpnStatus.listen((e) {
      _lastStatus = Map<dynamic, dynamic>.from(e);
      final state = (_lastStatus?['state'] ?? '').toString().toLowerCase();
      if (state.contains('connected')) {
        _active = true;
        _starting = false;
        _lastError = null;
      }
      if (state.contains('disconnected') || state.contains('stopped') || state.contains('error')) {
        _active = false;
        _starting = false;
      }
      notifyListeners();
    });

    // Best-effort restore: if the service is already running (rare), try to detect it.
    Future.microtask(_reconcileRunningState);
  }

  static final VpnManager instance = VpnManager._();

  final VpnService _service = VpnService();
  StreamSubscription? _statusSub;

  Map<dynamic, dynamic>? _lastStatus;
  Map<dynamic, dynamic>? get lastStatus => _lastStatus;

  bool _starting = false;
  bool _active = false;
  int _startToken = 0;
  String? _lastError;

  /// Whether VPN auto-start has already been triggered once this app session.
  bool _autoStartedOnce = false;

  /// Whether the last stop was triggered by the app lifecycle (auto-disconnect on leave).
  /// If true, we allow auto-reconnect on resume without resetting _autoStartedOnce.
  bool _stoppedByLifecycle = false;

  /// Whether the user manually stopped VPN after auto-start.
  /// If true, auto-start will NOT re-trigger until full app restart.
  bool _userManuallyStopped = false;

  bool get isStarting => _starting;
  bool get isActive => _active;
  String? get lastError => _lastError;

  /// Whether the user has VPN access (trial or premium). Null = not yet checked.
  bool? _hasVpnAccess;
  bool? get hasVpnAccess => _hasVpnAccess;

  /// Expose status stream for widgets that prefer StreamSubscription.
  Stream<Map<dynamic, dynamic>> get statusStream => _service.vpnStatus;

  /// Optional streams (may be empty depending on engine).
  Stream<Map<dynamic, dynamic>> get logStream => _service.logStream;

  Future<List<dynamic>> getLogs() => _service.getLogs();
  Future<void> clearLogs() => _service.clearLogs();

  // Backward-compatible alias.
  Future<void> stopVpn() => stop();

  List<String>? _blockedAppsCache;

  static const List<String> _alwaysBypassPackages = [
    'team.opay.pay',
    'org.telegram.messenger',
    'com.instagram.lite',
    'com.whatsapp',
    'com.spotify.music',
    'com.google.android.youtube',
  ];

  /// Check if user has VPN access (5-day trial or premium).
  /// If not signed in, still allow VPN (auto-start without auth).
  /// If trial expired and no premium, VPN will NOT start.
  Future<bool> checkVpnAccess() async {
    if (_hasVpnAccess != null) return _hasVpnAccess!;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Not signed in — allow VPN auto-start anyway
        _hasVpnAccess = true;
        return true;
      }
      final supabaseService = SupabaseService();
      final access = await supabaseService.checkAccessStatus(user.id);
      _hasVpnAccess = access['hasVpnAccess'] == true;
      return _hasVpnAccess!;
    } catch (_) {
      // If we can't check access, DENY VPN access to enforce trial expiration
      // User must have valid premium/trial to use VPN
      _hasVpnAccess = false;
      return false;
    }
  }

  /// Refresh VPN access status from Supabase (e.g. after payment).
  Future<void> refreshVpnAccess() async {
    _hasVpnAccess = null;
    await checkVpnAccess();
    notifyListeners();
  }

  Future<List<String>> _getBlockedApps() async {
    if (_blockedAppsCache != null) return _blockedAppsCache!;

    final pkg = await PackageInfo.fromPlatform();
    final myPkg = pkg.packageName;

    Future<List<String>> build({required bool includeSystemApps, required bool onlyLaunchable}) async {
      final apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: includeSystemApps,
        onlyAppsWithLaunchIntent: onlyLaunchable,
        includeAppIcons: false,
      );
      final pkgs = apps.map((a) => a.packageName).toSet();
      pkgs.remove(myPkg);
      return pkgs.toList()..sort();
    }

    var blocked = await build(includeSystemApps: true, onlyLaunchable: false);

    if (blocked.length > 700) {
      blocked = await build(includeSystemApps: true, onlyLaunchable: true);
    }
    if (blocked.length > 700) {
      blocked = await build(includeSystemApps: false, onlyLaunchable: true);
    }

    final set = blocked.toSet();
    set.addAll(_alwaysBypassPackages);

    _blockedAppsCache = set.toList()..sort();
    return _blockedAppsCache!;
  }

  /// Fetch the latest VPN config from Supabase and save it locally.
  /// Call this on app startup so VPN starts with the latest admin config.
  /// Non-blocking: if this fails, VPN will use the previously saved local config.
  Future<void> syncRemoteConfig() async {
    try {
      await VpnService.fetchAndSaveRemoteConfig();
    } catch (_) {
      // Non-blocking — use existing local config
    }
  }

  /// Auto-start VPN once when app opens. Only runs once per app session.
  /// Works even if user is not signed in.
  /// After lifecycle stop (app backgrounded), allows reconnect on resume.
  /// If user manually stops VPN, it will NOT auto-restart.
  ///
  /// If [ignoreAccessCheck] is true, VPN will start even if the user has no
  /// subscription/trial. Subscription enforcement can happen later (e.g. when
  /// entering the chat screen).
  Future<void> autoStartOnAppOpen({bool ignoreAccessCheck = false}) async {
    // If user manually stopped VPN, never auto-restart in this session
    if (_userManuallyStopped) return;

    // If auto-start was already done and we weren't stopped by lifecycle, skip
    if (_autoStartedOnce && !_stoppedByLifecycle) return;

    // If we were stopped by lifecycle (app went to background), allow reconnect
    _autoStartedOnce = true;
    _stoppedByLifecycle = false;

    if (!ignoreAccessCheck) {
      // Check VPN trial/premium access — if expired, do NOT start
      final hasAccess = await checkVpnAccess();
      if (!hasAccess) {
        _lastError = 'VPN trial expired. Subscribe to Premium.';
        notifyListeners();
        return;
      }
    }

    // Respect general VPN disabled flag
    final disabled = await VpnService.isVpnDisabled();
    if (disabled) return;

    await ensureStarted();
  }

  Future<void> ensureStarted({String? shareLink}) async {
    // Prevent overlapping starts.
    if (_starting) return;

    // If we think we're active, don't start again.
    if (_active) return;

    // If user manually stopped VPN, don't auto-restart
    if (_userManuallyStopped) return;

    // Respect access gate (general VPN disabled flag).
    final disabled = await VpnService.isVpnDisabled();
    if (disabled) return;

    // Check VPN trial/premium access (allows unsigned-in users)
    final hasAccess = await checkVpnAccess();
    if (!hasAccess) {
      _lastError = 'VPN trial expired. Subscribe to Premium.';
      notifyListeners();
      return;
    }

    final token = ++_startToken;
    _starting = true;
    _lastError = null;
    notifyListeners();

    try {
      // If no explicit share link provided, fetch remote config first, then use local
      String link;
      if (shareLink != null && shareLink.trim().isNotEmpty) {
        link = shareLink.trim();
      } else {
        // Try to fetch latest config from Supabase (non-blocking on failure)
        await syncRemoteConfig();
        link = (await VpnService.loadProxyUri()).trim();
      }

      if (link.isEmpty) {
        throw Exception('VPN config missing');
      }

      List<String> blocked = const [];
      try {
        blocked = await _getBlockedApps();
      } catch (_) {
        blocked = const [];
      }

      Object? lastErr;
      for (var attempt = 0; attempt < 3; attempt++) {
        if (token != _startToken) return;
        try {
          await _service
              .startVpn(shareLink: link, blockedApps: blocked)
              .timeout(const Duration(seconds: 40));
          lastErr = null;
          break;
        } catch (e) {
          lastErr = e;
          await Future.delayed(Duration(seconds: 2 + attempt * 2));
        }
      }
      if (lastErr != null) throw lastErr;

      if (token != _startToken) return;

      _active = true;
      // Clear manual stop flag when VPN successfully connects
      _userManuallyStopped = false;
    } catch (e) {
      if (token != _startToken) return;
      _active = false;
      _lastError = e.toString();
    } finally {
      if (token == _startToken) {
        _starting = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    _startToken++;
    _starting = false;
    _active = false;
    _lastError = null;
    notifyListeners();

    try {
      await _service.stopVpn().timeout(const Duration(seconds: 10));
    } catch (_) {}

    _lastStatus = {'engine': 'v2ray', 'state': 'disconnected', 'duration': 0};
    notifyListeners();
  }

  /// Stop VPN and mark as user manually stopped.
  /// This prevents auto-restart until the user manually reconnects or app restarts.
  Future<void> stopByUser() async {
    _userManuallyStopped = true;
    _autoStartedOnce = true; // Mark as started so autoStartOnAppOpen skips
    await stop();
  }

  /// Stop VPN due to app lifecycle (backgrounding).
  /// Marks as lifecycle stop so auto-reconnect works on resume.
  Future<void> stopForLifecycle() async {
    _stoppedByLifecycle = true;
    await stop();
  }

  /// Toggle VPN on/off. Returns the new state.
  Future<bool> toggle() async {
    if (_active) {
      // User is manually stopping VPN
      await stopByUser();
      return false;
    } else {
      // User is manually starting VPN - clear the manual stop flag
      _userManuallyStopped = false;
      await ensureStarted();
      return _active;
    }
  }

  /// Update config and optionally restart VPN if already active.
  /// This is called when admin updates VPN config — saves locally immediately
  /// so it persists across app restarts and works offline.
  Future<void> updateConfig(String shareLink, {bool restartIfActive = true}) async {
    final trimmed = shareLink.trim();
    if (trimmed.isEmpty) return;

    // Save to local storage immediately — this ensures offline access
    await VpnService.saveProxyUri(trimmed);

    if (restartIfActive) {
      await stop();
      await ensureStarted(shareLink: trimmed);
    }
  }

  Future<void> _reconcileRunningState() async {
    try {
      final lines = await _service.getLogs();
      final hasCore = lines.any((e) => e.toString().contains('coreVersion='));
      if (hasCore) {
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Reset auto-start flag (e.g. on logout so next login triggers it again).
  void resetAutoStart() {
    _autoStartedOnce = false;
    _stoppedByLifecycle = false;
    _userManuallyStopped = false;
    _hasVpnAccess = null;
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
