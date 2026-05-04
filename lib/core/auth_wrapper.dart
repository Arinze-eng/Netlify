import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../services/supabase_service.dart';
import '../services/vpn_manager.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _checkedBlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // User left the app — auto-disconnect VPN (lifecycle stop)
      VpnManager.instance.stopForLifecycle();
    } else if (state == AppLifecycleState.resumed) {
      // User came back — auto-reconnect VPN (only if not already starting)
      if (!VpnManager.instance.isStarting) {
        VpnManager.instance.autoStartOnAppOpen(ignoreAccessCheck: true);
      }
    }
  }

  Future<bool> _isUserBlocked() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final supabaseService = SupabaseService();
      final profile = await supabaseService.getProfile(user.id);
      if (profile != null && profile['is_blocked'] == true) {
        await supabaseService.signOut();
        if (mounted) {
          final reason = (profile['blocked_reason'] ?? 'Your account has been blocked by admin.').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reason),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // Check blocked status once per auth state change
          if (!_checkedBlocked) {
            _checkedBlocked = true;
            _isUserBlocked().then((blocked) => {
              if (blocked && mounted)
                {
                  setState(() {
                    _checkedBlocked = false;
                  })
                }
            });
          }

          return const ChatListScreen();
        }

        _checkedBlocked = false;
        return const LoginScreen();
      },
    );
  }
}
