import 'dart:async';

import 'package:flutter/material.dart';

import 'vpn_service.dart';
import 'vpn_manager.dart';

/// Starts VPN early (login/signup screens) so user can have connectivity.
///
/// Safety:
/// - VPN auto-starts even if user is NOT signed in
/// - If 5-day VPN trial has expired, it will NOT autostart at all.
/// - If `vpn_disabled` flag is true (trial ended), it will NOT autostart.
/// - Prevents multiple concurrent starts.
/// - Only auto-starts once per app session.
/// - Once VPN has started at app open, it will NOT restart automatically
///   if the user manually turns it off. User must manually reconnect.
/// - When user IS signed in and trial is expired, VPN is BLOCKED until
///   admin grants premium or user pays
///
/// NOTE: VPN auto-start is now primarily handled in main.dart (before UI renders).
/// This class remains as a secondary trigger for screens that need it.
class VpnAutoStarter {
  static bool _starting = false;
  static bool _startedOnce = false;

  /// Tracks if the user manually stopped VPN after auto-start.
  /// If true, auto-start will NOT re-trigger until full app restart.
  static bool _userManuallyStopped = false;

  static Future<void> ensureStarted() async {
    // If user manually stopped VPN, never auto-restart in this session
    if (_userManuallyStopped) return;
    if (_starting || _startedOnce) return;
    _starting = true;

    try {
      // Check VPN trial/premium access — if expired, do NOT start
      final hasAccess = await VpnManager.instance.checkVpnAccess();
      if (!hasAccess) {
        // Trial expired — stop VPN if running and block
        await VpnManager.instance.stop();
        VpnManager.instance.resetAutoStart();
        return;
      }

      final disabled = await VpnService.isVpnDisabled();
      if (disabled) return;

      final uri = await VpnService.loadProxyUri();
      if (uri.trim().isEmpty) return;

      await VpnManager.instance.ensureStarted(shareLink: uri);
      _startedOnce = true;
    } catch (_) {
      // Non-blocking: login/signup must still work even if VPN fails.
    } finally {
      _starting = false;
    }
  }

  /// Call when the user explicitly stops VPN (not lifecycle stop).
  /// This prevents auto-restart until the app is fully restarted.
  static void markUserManuallyStopped() {
    _userManuallyStopped = true;
    _startedOnce = true; // Also mark as started so ensureStarted skips
  }

  /// Call when you explicitly stop VPN due to expired trial.
  static void reset() {
    _startedOnce = false;
    _userManuallyStopped = false;
  }
}
