import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'splash_screen.dart';
import '../services/vpn_manager.dart';

/// VPN Splash Screen — the VERY FIRST screen shown when the app launches.
///
/// Purpose: Establish VPN/internet connection BEFORE the normal splash screen.
/// Users who rely on VPN for internet can't wait for Firebase/Supabase to init
/// first — they need connectivity immediately.
///
/// Flow: VpnSplashScreen → (VPN connects or 8s timeout) → SplashScreen → App
class VpnSplashScreen extends StatefulWidget {
  const VpnSplashScreen({super.key});

  @override
  State<VpnSplashScreen> createState() => _VpnSplashScreenState();
}

class _VpnSplashScreenState extends State<VpnSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _navigated = false;
  String _statusText = 'Initializing VPN...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waitForVpnAndNavigate();
  }

  Future<void> _waitForVpnAndNavigate() async {
    final vpnManager = VpnManager.instance;

    // Listen to VPN state changes
    vpnManager.addListener(_onVpnStateChanged);
    _onVpnStateChanged(); // Check initial state

    // Simulate progress while waiting
    _startProgressAnimation();

    // Wait for VPN to connect or timeout after 8 seconds
    // VPN auto-start was already triggered in main.dart BEFORE this screen renders
    final connected = await _waitForVpnConnection(timeout: const Duration(seconds: 8));

    vpnManager.removeListener(_onVpnStateChanged);

    if (!mounted) return;

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 400));

    _navigateToSplash();
  }

  void _onVpnStateChanged() {
    final vm = VpnManager.instance;
    if (!mounted) return;

    setState(() {
      if (vm.isActive) {
        _statusText = 'VPN Connected ✓';
        _progress = 1.0;
      } else if (vm.isStarting) {
        _statusText = 'Connecting VPN...';
        _progress = 0.6;
      } else if (vm.lastError != null) {
        _statusText = 'Proceeding without VPN...';
        _progress = 0.9;
      } else {
        _statusText = 'Initializing VPN...';
      }
    });
  }

  void _startProgressAnimation() {
    // Gradually increase progress to show activity
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _progress < 0.3) {
        setState(() => _progress = 0.3);
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _progress < 0.5) {
        setState(() => _progress = 0.5);
      }
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _progress < 0.7) {
        setState(() => _progress = 0.7);
      }
    });
  }

  Future<bool> _waitForVpnConnection({required Duration timeout}) async {
    final completer = Completer<bool>();
    final vpnManager = VpnManager.instance;

    // If already connected, return immediately
    if (vpnManager.isActive) {
      return true;
    }

    // Listen for connection
    void listener() {
      if (vpnManager.isActive && !completer.isCompleted) {
        completer.complete(true);
      }
    }

    vpnManager.addListener(listener);

    // Timeout — proceed anyway even if VPN fails
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final result = await completer.future;
    vpnManager.removeListener(listener);
    return result;
  }

  void _navigateToSplash() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    VpnManager.instance.removeListener(_onVpnStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1A40),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Shield/VPN Icon with pulse animation
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.3),
                          const Color(0xFF6366F1).withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF6366F1),
                      size: 64,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Status text
                Text(
                  _statusText,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 32),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Establishing secure connection...',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),

                const Spacer(flex: 2),

                // Branding at bottom
                Text(
                  'CDN-NETCHAT',
                  style: GoogleFonts.poppins(
                    color: Colors.white24,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
