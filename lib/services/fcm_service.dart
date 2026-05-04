import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'supabase_service.dart';

/// Top-level background message handler — MUST be a top-level function.
/// This is invoked by Firebase when a message arrives while the app is
/// in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolate
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Show a local notification for the background message
  final notification = message.notification;
  final data = message.data;

  if (notification != null) {
    final type = data['type'] ?? 'message';

    switch (type) {
      case 'call':
        await NotificationService.showIncomingCallNotification(
          title: notification.title ?? 'Incoming Call',
          body: notification.body ?? '',
          payload: data['thread_id'] ?? data['from_id'] ?? '',
        );
        break;
      case 'status':
        await NotificationService.showNewStatusNotification(
          title: notification.title ?? 'New Status',
          body: notification.body ?? '',
          payload: data['status_id'] ?? '',
        );
        break;
      case 'message':
      case 'group_message':
      default:
        await NotificationService.showIncomingMessageNotification(
          title: notification.title ?? 'CDN-NETCHAT',
          body: notification.body ?? '',
          payload: data['chat_id'] ?? data['thread_id'] ?? data['group_id'] ?? '',
        );
        break;
    }
  }
}

/// Firebase Cloud Messaging service for real-time push notifications.
///
/// [UPDATE #4] Fixed FCM token registration:
/// - Token is cached locally so it survives app restarts.
/// - Token is synced to Supabase immediately when user logs in,
///   not just on FCM init (which happens before login in main()).
/// - Works even when the app is completely closed/terminated.
/// - Background message handler shows notifications without opening the app.
class FcmService {
  FcmService._();
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  static const _kTokenPrefKey = 'cached_fcm_token';

  String? get fcmToken => _fcmToken;

  /// Initialize FCM: request permissions, get token, set up listeners.
  /// This is called from main() BEFORE the user logs in.
  /// Token sync to Supabase happens later when user signs in.
  Future<void> init() async {
    // Request notification permission (Android 13+ requires runtime permission)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    // Set foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background handler — this is the KEY for terminated-state notifications
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Get the FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token obtained: ${_fcmToken?.substring(0, 20)}...');

    // Cache token locally so we can sync it later after login
    if (_fcmToken != null) {
      await _cacheTokenLocally(_fcmToken!);
    }

    // Listen for token refresh and sync to server
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _cacheTokenLocally(newToken);
      // Auto-sync token to Supabase so Edge Function can always reach this device
      _syncTokenToSupabase();
    });

    // Foreground messages — show local notification
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Message opened app from background (user tapped notification)
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.messageId}');
      _handleMessageOpenedApp(message);
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial message: ${initialMessage.messageId}');
      _handleMessageOpenedApp(initialMessage);
    }

    // Subscribe to global topic for all users
    await _messaging.subscribeToTopic('all_users');

    // Create notification channels for FCM default channel
    await _ensureNotificationChannels();

    // NOTE: We do NOT sync token to Supabase here because the user
    // may not be logged in yet. Token sync happens in syncTokenToServer()
    // which is called AFTER successful sign-in.
  }

  /// Cache FCM token to SharedPreferences so it persists across app restarts.
  Future<void> _cacheTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenPrefKey, token);
    } catch (_) {}
  }

  /// Get the cached FCM token from SharedPreferences.
  Future<String?> getCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kTokenPrefKey);
    } catch (_) {
      return null;
    }
  }

  /// Sync FCM token to Supabase so Edge Function can send pushes
  /// even when the app is completely closed.
  /// This is the CRITICAL fix: only syncs when there's a logged-in user.
  Future<void> _syncTokenToSupabase() async {
    if (_fcmToken == null) return;
    try {
      final user = SupabaseService().currentUser;
      if (user != null) {
        debugPrint('Syncing FCM token to Supabase for user: ${user.id}');
        await SupabaseService().registerFcmToken(user.id, _fcmToken!);
        debugPrint('FCM token synced to Supabase successfully');
      } else {
        debugPrint('No logged-in user yet — FCM token will sync after login');
      }
    } catch (e) {
      debugPrint('Failed to sync FCM token to Supabase: $e');
      // Schedule a retry after 5 seconds
      Future.delayed(const Duration(seconds: 5), () => _syncTokenToSupabase());
    }
  }

  /// Store FCM token in Supabase for server-side push sending.
  /// Called after login to ensure the token is always up-to-date.
  /// [UPDATE #4] This is now the primary entry point for token sync.
  /// Called from sign-in flow to guarantee the token is written.
  Future<void> syncTokenToServer(String userId) async {
    // Use the in-memory token first, fallback to cached token
    final token = _fcmToken ?? await getCachedToken();
    if (token == null) {
      debugPrint('No FCM token available to sync for user: $userId');
      return;
    }

    _fcmToken = token; // Ensure in-memory token is set

    debugPrint('Syncing FCM token to server for user: $userId');
    try {
      await SupabaseService().registerFcmToken(userId, token);
      debugPrint('FCM token synced to server successfully');
    } catch (e) {
      debugPrint('Failed to sync FCM token to server: $e — will retry');
      // Retry up to 3 times with increasing delay
      for (var attempt = 1; attempt <= 3; attempt++) {
        await Future.delayed(Duration(seconds: attempt * 3));
        try {
          await SupabaseService().registerFcmToken(userId, token);
          debugPrint('FCM token sync retry #$attempt succeeded');
          return;
        } catch (_) {
          debugPrint('FCM token sync retry #$attempt failed');
        }
      }
    }
  }

  /// Handle messages received while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Determine notification type from data payload
    final type = data['type'] ?? 'message';

    switch (type) {
      case 'call':
        NotificationService.showIncomingCallNotification(
          title: notification.title ?? 'Incoming Call',
          body: notification.body ?? '',
          payload: data['thread_id'] ?? data['from_id'] ?? '',
        );
        break;
      case 'status':
        NotificationService.showNewStatusNotification(
          title: notification.title ?? 'New Status',
          body: notification.body ?? '',
          payload: data['status_id'] ?? '',
        );
        break;
      case 'message':
      case 'group_message':
      default:
        NotificationService.showIncomingMessageNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? '',
          payload: data['chat_id'] ?? data['thread_id'] ?? data['group_id'] ?? '',
        );
        break;
    }
  }

  /// Handle when user taps a notification that opens the app.
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    debugPrint('Notification tapped with data: $data');
    // Navigation to specific chat/status/call can be handled here
    // by posting to a global event bus or navigator key
  }

  /// Subscribe to a specific user's notification topic.
  /// Each user has a personal topic: user_{uid}
  Future<void> subscribeToUserTopic(String userId) async {
    await _messaging.subscribeToTopic('user_$userId');
    debugPrint('Subscribed to FCM topic: user_$userId');
  }

  /// Unsubscribe from a specific user's notification topic.
  Future<void> unsubscribeFromUserTopic(String userId) async {
    await _messaging.unsubscribeFromTopic('user_$userId');
  }

  /// Subscribe to a group's notification topic.
  Future<void> subscribeToGroupTopic(String groupId) async {
    await _messaging.subscribeToTopic('group_$groupId');
  }

  /// Unsubscribe from a group's notification topic.
  Future<void> unsubscribeFromGroupTopic(String groupId) async {
    await _messaging.unsubscribeFromTopic('group_$groupId');
  }

  /// Ensure Android notification channels exist for FCM default channel.
  Future<void> _ensureNotificationChannels() async {
    // Channels are already created by NotificationService.init()
    // This is a safety net for FCM-specific channel requirements.
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}
