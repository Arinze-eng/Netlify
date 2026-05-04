import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap - could navigate to chat
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Android 13+ runtime permission is handled by OS; we best-effort request.
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }

    // Create high-priority channel for message notifications
    try {
      const channel = AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Incoming chat messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (_) {}

    // Create high-priority channel for incoming call notifications
    try {
      const callChannel = AndroidNotificationChannel(
        'incoming_calls',
        'Incoming Calls',
        description: 'Incoming voice and video calls',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(callChannel);
    } catch (_) {}

    // [FIX #3] Create channel for status notifications
    try {
      const statusChannel = AndroidNotificationChannel(
        'status_updates',
        'Status Updates',
        description: 'New status updates from contacts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(statusChannel);
    } catch (_) {}
  }

  static Future<void> showNewMessage({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      category: AndroidNotificationCategory.message,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  /// [FIX #3] Show notification IMMEDIATELY when a new message arrives.
  /// This is called from the realtime stream listener - no delay.
  static Future<void> showIncomingMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      category: AndroidNotificationCategory.message,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// [FIX #3] Show notification when someone posts a new status
  static Future<void> showNewStatusNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'status_updates',
      'Status Updates',
      channelDescription: 'New status updates from contacts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show a high-priority notification for incoming calls
  /// This uses a full-screen intent style notification for maximum visibility
  static Future<void> showIncomingCallNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Incoming voice and video calls',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      category: AndroidNotificationCategory.call,
      // Full-screen intent for calls (shows over other apps on lock screen)
      fullScreenIntent: true,
      // Use default alarm sound for calls
      sound: RawResourceAndroidNotificationSound('ringtone'),
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
