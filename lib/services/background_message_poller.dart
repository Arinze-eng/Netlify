import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';

const String kBgPollTask = 'bg_poll_unread_messages';
const String kBgPollCallsTask = 'bg_poll_incoming_calls';

/// Top-level callback dispatcher for Workmanager.
/// Must be a top-level function, not a static method or closure.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Only run when connected
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) return true;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return true;

    try {
      if (task == kBgPollTask) {
        await _pollUnreadMessages(client, user.id);
      } else if (task == kBgPollCallsTask) {
        await _pollIncomingCalls(client, user.id);
      }
    } catch (_) {
      // ignore
    }

    return true;
  });
}

Future<void> _pollUnreadMessages(SupabaseClient client, String userId) async {
  try {
    // Fetch unread messages for me
    final res = await client
        .from('messages')
        .select('id,sender_id,receiver_id,content,message_type,created_at')
        .eq('receiver_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false)
        .limit(5);

    final list = (res as List).cast<Map>();
    if (list.isEmpty) return;

    // Notify latest
    final m = Map<String, dynamic>.from(list.first);
    final senderId = (m['sender_id'] ?? '').toString();
    final type = (m['message_type'] ?? 'text').toString();
    final body = type == 'text' || type == 'emoji'
        ? (m['content'] ?? '').toString()
        : type.toUpperCase();

    await NotificationService.showIncomingMessageNotification(
      title: 'New message',
      body: body.isEmpty ? 'New message' : body,
      payload: senderId,
    );
  } catch (_) {
    // ignore
  }
}

Future<void> _pollIncomingCalls(SupabaseClient client, String userId) async {
  try {
    // Check for recent call signals (last 30 seconds)
    final cutoff = DateTime.now().toUtc().subtract(const Duration(seconds: 30));
    final res = await client
        .from('call_signals')
        .select('id,from_id,type,payload,created_at')
        .eq('to_id', userId)
        .order('created_at', ascending: false)
        .limit(5);

    final list = (res as List).cast<Map>();
    if (list.isEmpty) return;

    // Check for recent call offers
    for (final raw in list) {
      final signal = Map<String, dynamic>.from(raw);
      final type = (signal['type'] ?? '').toString();
      final createdAt = DateTime.tryParse((signal['created_at'] ?? '').toString());
      if (createdAt == null) continue;
      if (createdAt.isBefore(cutoff)) continue; // Too old

      if (type == 'call_offer' || type == 'offer') {
        final payload = signal['payload'] as Map<String, dynamic>?;
        final isVideo = payload?['is_video'] == true;

        await NotificationService.showIncomingCallNotification(
          title: isVideo ? 'Incoming Video Call' : 'Incoming Call',
          body: 'Someone is calling you on CDN-NETCHAT',
          payload: (signal['from_id'] ?? '').toString(),
        );
        break; // Only notify once per poll
      }
    }
  } catch (_) {
    // ignore
  }
}

/// Best-effort background polling for unread messages and incoming calls.
///
/// Why: without FCM push, Android may not show notifications until the app opens.
/// This keeps a periodic job that checks unread messages and incoming calls,
/// and triggers local notifications.
///
/// Updated: polls every 15 minutes (minimum Android interval), but also runs
/// on app open to ensure notifications are always shown even if the user doesn't
/// have the app in the foreground.
class BackgroundMessagePoller {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    // Minimum periodic interval is ~15 minutes on Android.
    await Workmanager().registerPeriodicTask(
      'cdn_netchat_poll',
      kBgPollTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    // Also poll for incoming calls in background
    await Workmanager().registerPeriodicTask(
      'cdn_netchat_calls',
      kBgPollCallsTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
