import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/splash_screen.dart';
import 'services/vpn_manager.dart';
import 'services/notification_service.dart';
import 'services/background_message_poller.dart';
import 'services/supabase_service.dart';
import 'services/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── VPN auto-start FIRST (before anything else) ──
  // VPN starts immediately so users without data get internet access.
  // Premium checking happens AFTER the app loads (in ChatListScreen).
  // This is critical: people relying on VPN for internet can't wait for
  // Firebase/Supabase to initialize first.
  try {
    await VpnManager.instance.syncRemoteConfig();
  } catch (_) {}

  // Fire-and-forget VPN start — non-blocking, no premium gate
  unawaited(VpnManager.instance.autoStartOnAppOpen(ignoreAccessCheck: true));

  // ── Firebase initialization (FCM push notifications) ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Supabase initialization (serverless transport/signaling only) ──
  await Supabase.initialize(
    url: 'https://ljnparociyyggmxdewwv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqbnBhcm9jaXl5Z2dteGRld3d2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5Njk3MzYsImV4cCI6MjA5MjU0NTczNn0.Lr4UR7llvzC9QxQIwOGdRxn4-2hyRgqYXAnfDRC1-C8',
  );

  // ── Local notification channels ──
  await NotificationService.init();
  await BackgroundMessagePoller.init();

  // ── Firebase Cloud Messaging (real-time push notifications) ──
  await FcmService().init();

  // Listen for auth state changes and sync FCM token
  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.event == AuthChangeEvent.signedIn && event.session != null) {
      final userId = event.session!.user.id;
      debugPrint('Auth state: signed in as $userId — syncing FCM token');
      FcmService().syncTokenToServer(userId);
    }
  });

  // Cleanup expired media from Supabase on app open
  try {
    final supabaseService = SupabaseService();
    await supabaseService.cleanupExpiredSupabaseMedia();
  } catch (_) {}

  runApp(
    ChangeNotifierProvider.value(
      value: VpnManager.instance,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CDN-NETCHAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2AABEE),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F1F28),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B141A),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF0F1F28),
          contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
