import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../services/vpn_manager.dart';
import '../../../services/vpn_service.dart';

/// VPN UI widget — displays "Offline Mode VPN(60MB)".
///
/// This widget integrates directly with VpnManager for native VPN control.
/// No external VPN module app is needed.
///
/// VPN access is controlled by a 5-day trial from account creation.
/// After trial expires, user must have premium (admin-granted or paid).
///
/// VPN config is fetched from Supabase on app startup and saved locally.
/// If admin updates the config, it's synced on next app open or VPN toggle.
/// The local config is used when offline.
class VpnCard extends StatefulWidget {
  const VpnCard({super.key});

  @override
  State<VpnCard> createState() => _VpnCardState();
}

class _VpnCardState extends State<VpnCard> {
  bool _hasVpnAccess = false;
  bool _isPremium = false;
  int _vpnTrialDaysLeft = 0;
  bool _loadingAccess = true;

  @override
  void initState() {
    super.initState();
    _loadVpnAccess();
  }

  Future<void> _loadVpnAccess() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Not signed in — allow VPN auto-start (per requirement)
        if (!mounted) return;
        setState(() {
          _hasVpnAccess = true; // Allow VPN for unsigned-in users
          _isPremium = false;
          _vpnTrialDaysLeft = 5; // Default trial days
          _loadingAccess = false;
        });
        return;
      }
      final supabaseService = SupabaseService();
      final access = await supabaseService.checkAccessStatus(user.id);
      if (!mounted) return;
      final vpnAccess = access['hasVpnAccess'] == true;
      setState(() {
        _hasVpnAccess = vpnAccess;
        _isPremium = access['isPremium'] == true;
        _vpnTrialDaysLeft = access['vpnTrialDaysLeft'] ?? 0;
        _loadingAccess = false;
      });

      // If VPN access is denied, stop any running VPN immediately
      if (!vpnAccess) {
        await VpnManager.instance.stop();
        VpnManager.instance.resetAutoStart();
      }
    } catch (_) {
      if (mounted) {
        // On error, deny VPN access by default — user must have valid access
        setState(() {
          _hasVpnAccess = false;
          _loadingAccess = false;
        });
      }
    }
  }

  void _showVpnAccessDenied() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.vpn_lock_rounded, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Offline Mode VPN Trial Expired',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your 5-day VPN trial has ended. Subscribe to Premium to continue using Offline Mode VPN(60MB).',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/payment');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Get Premium', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Maybe Later', style: GoogleFonts.poppins(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAccess) {
      return Card(
        color: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_lock_rounded, color: Color(0xFF2AABEE), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Offline Mode VPN(60MB)',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                if (_isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green),
                      color: Colors.green.withOpacity(0.12),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (_hasVpnAccess)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.8)),
                      color: Colors.orangeAccent.withOpacity(0.12),
                    ),
                    child: Text(
                      'TRIAL: $_vpnTrialDaysLeft days left',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.redAccent),
                      color: Colors.redAccent.withOpacity(0.12),
                    ),
                    child: Text(
                      'EXPIRED',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_hasVpnAccess) ...[
              Text(
                'Your 5-day VPN trial has ended. Upgrade to Premium for Offline Mode VPN access.',
                style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 12),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/payment');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Get Premium', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              Text(
                _isPremium
                    ? 'Premium Offline Mode VPN(60MB) active. Connect securely.'
                    : 'VPN trial active ($_vpnTrialDaysLeft days remaining). Toggle below.',
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              // VPN Toggle Button using VpnManager
              _buildVpnToggle(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVpnToggle() {
    return ListenableBuilder(
      listenable: VpnManager.instance,
      builder: (context, _) {
        final vm = VpnManager.instance;
        final isActive = vm.isActive;
        final isStarting = vm.isStarting;
        final error = vm.lastError;

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (!_hasVpnAccess) {
                    _showVpnAccessDenied();
                    return;
                  }
                  if (isStarting) return;

                  if (!isActive) {
                    // Before starting, try to sync the latest config from Supabase
                    // This ensures admin VPN config changes are picked up immediately
                    try {
                      await VpnService.fetchAndSaveRemoteConfig();
                    } catch (_) {
                      // Non-blocking — use existing local config
                    }
                  }

                  await vm.toggle();
                  // Refresh access after toggle (in case premium was activated)
                  _loadVpnAccess();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive
                      ? Colors.redAccent.withOpacity(0.85)
                      : const Color(0xFF2AABEE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: isStarting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.power_settings_new_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isActive ? 'Turn OFF VPN' : 'Turn ON VPN',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connected',
                    style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (error != null && !isActive) ...[
              const SizedBox(height: 8),
              Text(
                error.replaceAll('Exception: ', ''),
                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }
}
