import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_wrapper.dart';
import '../services/vpn_manager.dart';
import '../services/supabase_service.dart';

/// Splash screen that shows the app logo while VPN initializes.
/// VPN starts IMMEDIATELY when the logo shows (no premium gate on splash).
/// Premium checking happens after the app loads (in ChatListScreen).
/// This ensures users without data get VPN internet access right away.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startVpnAndNavigate();
  }

  Future<void> _startVpnAndNavigate() async {
    // VPN was already kicked off in main.dart as fire-and-forget.
    // Here we wait briefly for it to connect, but DO NOT block on premium.
    // The VPN starts immediately — premium is checked later in ChatListScreen.
    try {
      await VpnManager.instance.autoStartOnAppOpen(ignoreAccessCheck: true).timeout(
            const Duration(seconds: 6),
          );
    } catch (_) {
      // VPN failed or timed out — proceed to app anyway
    }

    // Brief splash visibility for branding (logo is shown sharp immediately)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    _navigateToApp();
  }

  void _navigateToApp() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // App Logo / Icon — shown immediately and sharp
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Color(0xFF6366F1),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                // App Name
                Text(
                  'CDN-NETCHAT',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure Chat • VPN Protected',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const Spacer(flex: 2),
                // VPN Status Indicator — shows VPN is connecting/connected
                ListenableBuilder(
                  listenable: VpnManager.instance,
                  builder: (context, _) {
                    final vm = VpnManager.instance;
                    String statusText;
                    Color statusColor;

                    if (vm.isActive) {
                      statusText = 'VPN Connected ✓';
                      statusColor = Colors.greenAccent;
                    } else if (vm.isStarting) {
                      statusText = 'Connecting VPN...';
                      statusColor = const Color(0xFF2AABEE);
                    } else if (vm.lastError != null) {
                      statusText = 'VPN: Tap to connect';
                      statusColor = Colors.orangeAccent;
                    } else {
                      statusText = 'Initializing...';
                      statusColor = Colors.white38;
                    }

                    return Column(
                      children: [
                        // Pulsing dot
                        FadeTransition(
                          opacity: _animController,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Loading indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
