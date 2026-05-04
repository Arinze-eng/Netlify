import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'fcm_service.dart';

/// Supabase Service — Serverless/Blob Architecture
///
/// DESIGN PRINCIPLE:
/// ─────────────────
/// Supabase acts as a SERVERLESS TRANSPORT LAYER ONLY.
/// It is NOT a persistent data store.
///
/// • Messages: Transported in real-time via Supabase Realtime.
///   The PRIMARY copy lives on-device (Isar local DB) permanently.
///   Supabase auto-cleans old messages (3h TTL) — local copies are never deleted.
///
/// • Media/Files: Uploaded to Supabase Storage as temporary transport blobs.
///   Auto-deleted from Supabase after 3 hours. The device-local copy is PERMANENT.
///
/// • Push Notifications: FCM tokens stored in Supabase `fcm_tokens` table
///   so the Supabase Edge Function can trigger Firebase Cloud Messaging
///   for real-time notifications even when the app is closed.
///
/// • Real-time features (typing, call signaling, presence): All use Supabase
///   Realtime — these are ephemeral by nature and never need permanent storage.
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton — all screens share one instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Admin shared secret (UI password). This is used only to call admin RPCs.
  static const String adminSecret = 'nethuntersupreme@davidnwan';

  // [UPDATE #1] Media auto-delete duration reduced from 10h to 3h
  // Cloud copy is deleted after this; device copy is PERMANENT.
  static const Duration mediaAutoDeleteDuration = Duration(hours: 3);

  // [UPDATE #1] Message auto-delete duration from Supabase reduced from 10h to 3h
  // Local copy stays FOREVER
  static const Duration messageAutoDeleteDuration = Duration(hours: 3);

  // ---- FCM Token Management ----
  // Store the user's FCM token in Supabase so our Edge Function can
  // send push notifications to them even when the app is terminated.

  Future<void> registerFcmToken(String userId, String fcmToken) async {
    try {
      debugPrint('registerFcmToken: writing token for user $userId');
      await _client.from('fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': fcmToken,
        'platform': Platform.operatingSystem,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      debugPrint('registerFcmToken: SUCCESS for user $userId');
    } catch (e) {
      debugPrint('registerFcmToken: FAILED for user $userId — $e');
    }
  }

  Future<void> removeFcmToken(String userId) async {
    try {
      await _client.from('fcm_tokens').delete().eq('user_id', userId);
    } catch (_) {}
  }

  // ---- Authentication ----
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final chatUuid = const Uuid().v4().substring(0, 8).toUpperCase();

    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': chatUuid,
        'display_name': displayName.trim(),
      },
    );

    try {
      final u = res.user ?? _client.auth.currentUser;
      if (res.session != null && u != null) {
        await _client.from('auth_events').insert({'user_id': u.id, 'event': 'sign_up'});

        // [UPDATE #4] Use syncTokenToServer for reliable token registration
        // with retry logic and local cache fallback
        await FcmService().syncTokenToServer(u.id);
      }
    } catch (_) {}

    return res;
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);

    try {
      final u = res.user ?? _client.auth.currentUser;
      if (u != null) {
        await _client.from('auth_events').insert({'user_id': u.id, 'event': 'sign_in'});

        // [UPDATE #4] Use syncTokenToServer for reliable token registration
        // with retry logic and local cache fallback.
        // This is the PRIMARY place where FCM token gets written to Supabase.
        await FcmService().syncTokenToServer(u.id);

        // Subscribe to personal FCM topic
        await FcmService().subscribeToUserTopic(u.id);
      }
    } catch (_) {}

    return res;
  }

  Future<void> signOut() async {
    try {
      final u = _client.auth.currentUser;
      if (u != null) {
        await _client.from('auth_events').insert({'user_id': u.id, 'event': 'sign_out'});
        // Remove FCM token on sign-out
        await removeFcmToken(u.id);
        await FcmService().unsubscribeFromUserTopic(u.id);
      }
    } catch (_) {}

    await _client.auth.signOut();
  }

  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  User? get currentUser => _client.auth.currentUser;

  // ---- Profile Management ----
  Future<List<Map<String, dynamic>>> listProfiles() async {
    final data = await _client
        .from('profiles')
        .select('id,email,username,display_name,last_seen,hide_last_seen,hide_read_receipts,created_at,about,avatar_url')
        .order('created_at', ascending: false);

    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await _client
        .from('profiles')
        .select('id,email,username,display_name,trial_ends_at,is_subscribed,subscription_expiry,last_seen,hide_last_seen,hide_read_receipts,created_at,is_blocked,blocked_reason,blocked_at,about,avatar_url')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getProfileByChatUuid(String chatUuid) async {
    return await _client
        .from('profiles')
        .select('id,email,username,display_name,trial_ends_at,is_subscribed,subscription_expiry,last_seen,hide_last_seen,hide_read_receipts,created_at,about,avatar_url')
        .eq('username', chatUuid)
        .maybeSingle();
  }

  Future<void> updateLastSeen(String userId) async {
    await _client.rpc('touch_last_seen');
  }

  Stream<Map<String, dynamic>> streamProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => Map<String, dynamic>.from(data.first));
  }

  // ---- Privacy settings ----
  Future<void> updatePrivacySettings({bool? hideLastSeen, bool? hideReadReceipts}) async {
    final u = _client.auth.currentUser;
    if (u == null) throw Exception('Not signed in');

    final patch = <String, dynamic>{};
    if (hideLastSeen != null) patch['hide_last_seen'] = hideLastSeen;
    if (hideReadReceipts != null) patch['hide_read_receipts'] = hideReadReceipts;
    if (patch.isEmpty) return;

    await _client.from('profiles').update(patch).eq('id', u.id);
  }

  Future<Map<String, dynamic>?> getMyPrivacySettings() async {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    return await _client.from('profiles').select('hide_last_seen,hide_read_receipts').eq('id', u.id).maybeSingle();
  }

  // ---- Threads ----
  Future<List<Map<String, dynamic>>> getChatThreads() async {
    final res = await _client.rpc('get_chat_threads');
    final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return list;
  }

  // ---- Delete chat thread ----
  Future<void> deleteChatThread(String otherUserId) async {
    final u = _client.auth.currentUser;
    if (u == null) throw Exception('Not signed in');

    await _client
        .from('messages')
        .delete()
        .eq('sender_id', u.id)
        .eq('receiver_id', otherUserId);

    await _client
        .from('messages')
        .delete()
        .eq('sender_id', otherUserId)
        .eq('receiver_id', u.id);
  }

  // ---- Messages ----
  // NOTE: Supabase is the TRANSPORT layer. Messages are delivered via
  // Supabase Realtime, then stored permanently on-device via Isar.
  // Supabase auto-cleans messages after messageAutoDeleteDuration (3h).

  Stream<List<Map<String, dynamic>>> getMessages(String currentUserId, String otherUserId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          final filtered = data
              .where((m) =>
                  (m['sender_id'] == currentUserId && m['receiver_id'] == otherUserId) ||
                  (m['sender_id'] == otherUserId && m['receiver_id'] == currentUserId))
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          filtered.sort((a, b) {
            final aPinned = a['is_pinned'] == true;
            final bPinned = b['is_pinned'] == true;
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;
            return a['created_at'].compareTo(b['created_at']);
          });
          return filtered;
        });
  }

  Stream<List<Map<String, dynamic>>> streamIncomingMessages(String userId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          final filtered = data
              .where((m) => m['receiver_id'] == userId && m['is_read'] == false)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          return filtered;
        });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? mediaPath,
    String? mediaMime,
    int? mediaDurationMs,
    String? mediaName,
    int? mediaSizeBytes,
    int? replyToId,
    String? caption,
    DateTime? expiresAt,
    bool viewOnce = false,
    String? reactions,
    bool isRichText = false,
    String? richTextJson,
    bool isForwarded = false,
    String? forwardedFromId,
  }) async {
    DateTime? mediaExpiresAt;
    if (mediaPath != null && mediaPath.isNotEmpty) {
      mediaExpiresAt = DateTime.now().add(mediaAutoDeleteDuration);
    }

    await _client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
      'media_path': mediaPath,
      'media_mime': mediaMime,
      'media_duration_ms': mediaDurationMs,
      'media_name': mediaName,
      'media_size_bytes': mediaSizeBytes,
      'reply_to_id': replyToId,
      'caption': caption,
      'expires_at': expiresAt?.toIso8601String(),
      'view_once': viewOnce,
      'reactions': reactions,
      'media_expires_at': mediaExpiresAt?.toIso8601String(),
      'is_rich_text': isRichText,
      'rich_text_json': richTextJson,
      'is_forwarded': isForwarded,
      'forwarded_from_id': forwardedFromId,
    });

    // [UPDATE #2] Trigger push notification via Supabase Edge Function
    // The Edge Function reads the receiver's FCM token from fcm_tokens
    // and sends a Firebase Cloud Message — works even when app is terminated.
    try {
      await _client.functions.invoke('send-push-notification', body: {
        'receiver_id': receiverId,
        'sender_id': senderId,
        'message_type': messageType,
        'content': messageType == 'text' ? content : '[${messageType.capitalize()}]',
        'type': 'message',
      });
    } catch (_) {
      // Push notification is best-effort; message is already delivered via Realtime
    }
  }

  Future<void> editMessage({required int messageId, required String newContent}) async {
    await _client.from('messages').update({
      'content': newContent,
      'edited_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  Future<void> editRichTextMessage({required int messageId, required String content, required String richTextJson}) async {
    await _client.from('messages').update({
      'content': content,
      'rich_text_json': richTextJson,
      'edited_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  Future<void> deleteMessageForEveryone({required int messageId}) async {
    await _client.from('messages').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'message_type': 'deleted',
      'content': '',
      'caption': null,
      'media_path': null,
      'media_mime': null,
      'media_duration_ms': null,
    }).eq('id', messageId);
  }

  Future<void> deleteMessageForMe({required int messageId, required bool iAmSender}) async {
    final patch = <String, dynamic>{};
    if (iAmSender) {
      patch['deleted_for_sender'] = true;
    } else {
      patch['deleted_for_receiver'] = true;
    }
    await _client.from('messages').update(patch).eq('id', messageId);
  }

  Future<void> markViewOnceViewed({required int messageId, required bool iAmSender}) async {
    final patch = <String, dynamic>{};
    if (iAmSender) {
      patch['viewed_by_sender'] = true;
    } else {
      patch['viewed_by_receiver'] = true;
    }
    await _client.from('messages').update(patch).eq('id', messageId);
  }

  Future<void> toggleLike(int messageId, bool isLiked) async {
    await _client.from('messages').update({'is_liked': isLiked}).eq('id', messageId);
  }

  Future<void> starMessage({required int messageId, required bool starred}) async {
    await _client.from('messages').update({'is_starred': starred}).eq('id', messageId);
  }

  Future<List<Map<String, dynamic>>> getStarredMessages(String userId) async {
    final res = await _client
        .from('messages')
        .select('id,sender_id,receiver_id,content,message_type,created_at,is_starred,media_path,media_mime')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .eq('is_starred', true)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> setReaction({required int messageId, required String emoji}) async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    final msg = await _client.from('messages').select('reactions').eq('id', messageId).maybeSingle();
    Map<String, dynamic> reactions = {};
    if (msg != null && msg['reactions'] != null) {
      try {
        reactions = Map<String, dynamic>.from(msg['reactions'] as Map);
      } catch (_) {}
    }
    if (reactions[u.id] == emoji) {
      reactions.remove(u.id);
    } else {
      reactions[u.id] = emoji;
    }
    await _client.from('messages').update({'reactions': reactions}).eq('id', messageId);
  }

  Future<void> pinMessage({required int messageId, required bool pinned}) async {
    await _client.from('messages').update({'is_pinned': pinned}).eq('id', messageId);
  }

  Future<void> markAsRead(String currentUserId, String otherUserId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('receiver_id', currentUserId)
        .eq('sender_id', otherUserId)
        .eq('is_read', false);
  }

  Future<List<Map<String, dynamic>>> fetchConversationOnce(String currentUserId, String otherUserId) async {
    final res = await _client
        .from('messages')
        .select(
          'id,sender_id,receiver_id,content,is_liked,is_read,created_at,message_type,media_path,media_mime,media_duration_ms,reply_to_id,edited_at,deleted_at,deleted_for_sender,deleted_for_receiver,caption,expires_at,view_once,viewed_by_sender,viewed_by_receiver,reactions,is_pinned,media_name,media_size_bytes,media_expires_at,is_rich_text,rich_text_json,is_forwarded,forwarded_from_id,is_starred',
        )
        .or(
          'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
        )
        .order('created_at', ascending: true);

    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---- Media (Supabase Storage: TEMPORARY TRANSPORT BLOBS) ----
  // Media is uploaded to Supabase Storage as a temporary transport mechanism.
  // [UPDATE #1] Auto-deleted after mediaAutoDeleteDuration (3h).
  // The PERMANENT copy lives on the user's device.

  Future<String> uploadChatMedia({
    required String ownerUserId,
    required List<int> bytes,
    required String ext,
    required String mime,
  }) async {
    final id = const Uuid().v4();
    final safeExt = ext.trim().isEmpty ? 'bin' : ext.trim().toLowerCase();
    final path = '$ownerUserId/$id.$safeExt';

    Object? lastErr;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        await _client.storage
            .from('chat_media')
            .uploadBinary(
              path,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(contentType: mime, upsert: true),
            )
            .timeout(const Duration(seconds: 60));

        // Also save permanently to device local storage
        await _saveMediaToDevice(bytes, '$id.$safeExt');

        return path;
      } catch (e) {
        lastErr = e;
        final delayMs = 500 * (1 << attempt);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    throw Exception('Upload failed after retries: $lastErr');
  }

  Future<String> createSignedChatMediaUrl(String path, {int expiresInSeconds = 60 * 60}) async {
    final res = await _client.storage.from('chat_media').createSignedUrl(path, expiresInSeconds);
    return res;
  }

  /// Download media to local cache (PERMANENT on-device storage)
  /// This is the PRIMARY storage — Supabase copy is temporary transport only.
  Future<String> cacheMediaLocally({
    required String mediaPath,
    required String mediaMime,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(dir.path, 'chat_media_cache'));
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName = p.basename(mediaPath);
      final localPath = p.join(cacheDir.path, fileName);

      // If already cached locally, return immediately (device copy is PERMANENT)
      if (await File(localPath).exists()) {
        return localPath;
      }

      // Download from Supabase transport blob
      final bytes = await _client.storage.from('chat_media').download(mediaPath);
      await File(localPath).writeAsBytes(bytes, flush: true);

      return localPath;
    } catch (_) {
      return await createSignedChatMediaUrl(mediaPath);
    }
  }

  Future<void> deleteChatMediaForMessage(int messageId) async {
    await _client.rpc('delete_chat_media_for_message', params: {
      'p_message_id': messageId,
    });
  }

  Future<void> scheduleMediaAutoDelete(int messageId) async {
    try {
      await _client.from('messages').update({
        'media_expires_at': DateTime.now().add(mediaAutoDeleteDuration).toIso8601String(),
      }).eq('id', messageId);
    } catch (_) {}
  }

  /// Cleanup expired media from Supabase Storage (cloud transport blobs only).
  /// Local copies on device are NEVER deleted.
  Future<void> cleanupExpiredSupabaseMedia() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final expired = await _client
          .from('messages')
          .select('id,media_path')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .lt('media_expires_at', DateTime.now().toUtc().toIso8601String())
          .not('media_path', 'is', null);

      for (final msg in expired) {
        final mediaPath = msg['media_path'] as String?;
        if (mediaPath != null && mediaPath.isNotEmpty) {
          try {
            await _client.storage.from('chat_media').remove([mediaPath]);
            await _client.from('messages').update({
              'media_path': null,
              'media_mime': null,
            }).eq('id', msg['id']);
          } catch (_) {}
        }
      }

      final expiredContent = await _client
          .from('messages')
          .select('id,message_type,media_path')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .lt('media_expires_at', DateTime.now().toUtc().toIso8601String())
          .neq('message_type', 'deleted');

      for (final msg in expiredContent) {
        try {
          final mediaPath = msg['media_path'] as String?;
          if (mediaPath != null && mediaPath.isNotEmpty) {
            try {
              await _client.storage.from('chat_media').remove([mediaPath]);
            } catch (_) {}
          }
          await _client.from('messages').update({
            'media_path': null,
            'media_mime': null,
            'media_duration_ms': null,
            'media_size_bytes': null,
            'media_name': null,
            'caption': null,
          }).eq('id', msg['id']);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Save media bytes permanently to device storage
  Future<String> _saveMediaToDevice(List<int> bytes, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(dir.path, 'permanent_media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final localPath = p.join(mediaDir.path, fileName);
      if (!await File(localPath).exists()) {
        await File(localPath).writeAsBytes(bytes, flush: true);
      }
      return localPath;
    } catch (_) {
      return '';
    }
  }

  // ---- File Upload (TEMPORARY TRANSPORT) ----
  Future<String> uploadFile({
    required String ownerUserId,
    required List<int> bytes,
    required String fileName,
    required String mime,
  }) async {
    final id = const Uuid().v4();
    final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    final safeExt = ext.isEmpty ? 'bin' : ext;
    final path = '$ownerUserId/files/$id.$safeExt';

    // Save permanently to device first
    await _saveMediaToDevice(bytes, '${id}.$safeExt');

    Object? lastErr;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        await _client.storage
            .from('chat_media')
            .uploadBinary(
              path,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(contentType: mime, upsert: true),
            )
            .timeout(const Duration(seconds: 120));

        return path;
      } catch (e) {
        lastErr = e;
        final delayMs = 500 * (1 << attempt);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    throw Exception('File upload failed after retries: $lastErr');
  }

  // ---- Status Media Upload (TEMPORARY TRANSPORT) ----
  Future<String> uploadStatusMedia({
    required String userId,
    required List<int> bytes,
    required String ext,
    required String mime,
  }) async {
    final id = const Uuid().v4();
    final safeExt = ext.trim().isEmpty ? 'bin' : ext.trim().toLowerCase();
    final path = 'status/$userId/$id.$safeExt';

    // Save permanently to device
    await _saveMediaToDevice(bytes, 'status_$id.$safeExt');

    await _client.storage
        .from('chat_media')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mime, upsert: true),
        )
        .timeout(const Duration(seconds: 60));

    return path;
  }

  // ---- Typing indicator (ephemeral — perfect for serverless) ----
  Future<void> setTyping({required String receiverId, required bool isTyping}) async {
    await _client.rpc('set_typing', params: {
      'p_receiver_id': receiverId,
      'p_is_typing': isTyping,
    });
  }

  Stream<bool> streamIsOtherTyping({required String otherUserId}) async* {
    final me = _client.auth.currentUser;
    if (me == null) {
      yield false;
      return;
    }

    yield* _client
        .from('typing_events')
        .stream(primaryKey: ['sender_id', 'receiver_id'])
        .map((rows) {
          final filtered = rows.where((r) =>
            r['sender_id'] == otherUserId && r['receiver_id'] == me.id
          ).toList();
          if (filtered.isEmpty) return false;
          final r = Map<String, dynamic>.from(filtered.first);
          final isTyping = r['is_typing'] == true;
          final updatedAt = DateTime.tryParse((r['updated_at'] ?? '').toString());
          if (!isTyping) return false;
          if (updatedAt == null) return true;
          return DateTime.now().toUtc().difference(updatedAt.toUtc()).inSeconds <= 6;
        });
  }

  // ---- Per-user blocking ----
  Future<bool> isBlockedByMe(String otherUserId) async {
    final u = _client.auth.currentUser;
    if (u == null) return false;

    final res = await _client
        .from('user_blocks')
        .select('blocker_id')
        .eq('blocker_id', u.id)
        .eq('blocked_id', otherUserId)
        .maybeSingle();

    return res != null;
  }

  Future<void> blockUser(String otherUserId) async {
    final u = _client.auth.currentUser;
    if (u == null) throw Exception('Not signed in');

    await _client.from('user_blocks').insert({
      'blocker_id': u.id,
      'blocked_id': otherUserId,
    });
  }

  Future<void> unblockUser(String otherUserId) async {
    final u = _client.auth.currentUser;
    if (u == null) throw Exception('Not signed in');

    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', u.id)
        .eq('blocked_id', otherUserId);
  }

  // ---- Call signaling (ephemeral — perfect for serverless) ----
  // [UPDATE #3] Real-time calls via Supabase Realtime + WebRTC
  Future<void> sendCallSignal({
    required String toId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('call_signals').insert({
      'from_id': _client.auth.currentUser?.id,
      'to_id': toId,
      'type': type,
      'payload': payload,
    });

    // [UPDATE #2] Trigger push notification for incoming call via FCM
    // This ensures the callee gets notified even if app is terminated
    try {
      await _client.functions.invoke('send-push-notification', body: {
        'receiver_id': toId,
        'sender_id': _client.auth.currentUser?.id ?? '',
        'message_type': 'call',
        'content': type == 'video_call' ? 'Video call' : 'Voice call',
        'type': 'call',
      });
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamCallSignals(String selfId) {
    return _client
        .from('call_signals')
        .stream(primaryKey: ['id'])
        .eq('to_id', selfId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }

  Future<void> cleanupOldCallSignals() async {
    try {
      final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      await _client
          .from('call_signals')
          .delete()
          .lt('created_at', cutoff.toIso8601String());
    } catch (_) {}
  }

  // ---- Missed call logging ----
  Future<void> logMissedCall({required String callerId, required String receiverId, required bool isVideo}) async {
    try {
      await _client.from('call_history').insert({
        'caller_id': callerId,
        'receiver_id': receiverId,
        'call_type': isVideo ? 'video' : 'audio',
        'status': 'missed',
        'started_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> logCompletedCall({
    required String callerId,
    required String receiverId,
    required bool isVideo,
    required int durationSeconds,
  }) async {
    try {
      await _client.from('call_history').insert({
        'caller_id': callerId,
        'receiver_id': receiverId,
        'call_type': isVideo ? 'video' : 'audio',
        'status': 'completed',
        'duration_seconds': durationSeconds,
        'started_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamCallHistory(String userId) async* {
    try {
      yield* _client
          .from('call_history')
          .stream(primaryKey: ['id'])
          .map((rows) {
            final filtered = rows.where((r) =>
              r['caller_id'] == userId || r['receiver_id'] == userId
            ).toList();
            filtered.sort((a, b) => (b['started_at'] ?? '').toString().compareTo((a['started_at'] ?? '').toString()));
            return filtered.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
    } catch (_) {
      yield [];
    }
  }

  // ---- VPN remote config ----
  Future<String?> getRemoteVpnShareLink() async {
    final res = await _client.rpc('get_vpn_config');
    if (res == null) return null;
    final list = (res as List);
    if (list.isEmpty) return null;
    final row = Map<String, dynamic>.from(list.first as Map);
    final link = (row['v2ray_share_link'] ?? row['share_link'] ?? '').toString().trim();
    return link.isNotEmpty ? link : null;
  }

  // ---- Trial & Subscription Logic ----
  static const int vpnTrialDays = 5;
  static const int appTrialDays = 30;

  Future<Map<String, dynamic>> checkAccessStatus(String userId) async {
    final profile = await getProfile(userId);

    if (profile == null) {
      return {
        'hasAccess': true,
        'isPremium': false,
        'hasVpnAccess': false,
        'reason': 'Trial Pending (profile sync)',
      };
    }

    final now = DateTime.now();

    final trialEndsRaw = profile['trial_ends_at'];
    final DateTime? trialEndsAt = trialEndsRaw == null ? null : DateTime.tryParse(trialEndsRaw.toString());
    final createdAtRaw = profile['created_at'];
    final DateTime? createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw.toString());

    final effectiveTrialEnd = trialEndsAt ?? (createdAt?.add(Duration(days: appTrialDays)));
    final bool isTrialActive = effectiveTrialEnd == null ? true : now.isBefore(effectiveTrialEnd);

    final bool isSubscribed = profile['is_subscribed'] == true;
    final expiryRaw = profile['subscription_expiry'];
    final DateTime? expiry = expiryRaw == null ? null : DateTime.tryParse(expiryRaw.toString());
    final bool subscriptionValid = isSubscribed && (expiry == null ? false : now.isBefore(expiry));

    final bool isVpnTrialActive = createdAt != null
        ? now.isBefore(createdAt.add(Duration(days: vpnTrialDays)))
        : true;

    final bool hasVpnAccess = subscriptionValid || isVpnTrialActive;
    final bool hasAccess = subscriptionValid || isTrialActive;

    return {
      'hasAccess': hasAccess,
      'isPremium': subscriptionValid,
      'hasVpnAccess': hasVpnAccess,
      'vpnTrialDaysLeft': createdAt != null
          ? (createdAt.add(Duration(days: vpnTrialDays)).difference(now).inDays).clamp(0, vpnTrialDays)
          : vpnTrialDays,
      'appTrialDaysLeft': effectiveTrialEnd != null
          ? (effectiveTrialEnd.difference(now).inDays).clamp(0, appTrialDays)
          : appTrialDays,
      'reason': subscriptionValid
          ? 'Subscription Active'
          : (isTrialActive ? 'Trial Active' : 'Trial Expired'),
    };
  }

  Future<void> activateSubscription(String userId) async {
    await _client.from('profiles').update({
      'is_subscribed': true,
      'subscription_expiry': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    }).eq('id', userId);
  }

  // ---- Status (WhatsApp-like stories) ----
  Future<void> createStatus({
    required String userId,
    required String statusType,
    String? content,
    String? mediaPath,
    String? mediaMime,
    String backgroundColor = '#6366F1',
    bool isBold = false,
    String? caption,
  }) async {
    await _client.from('status').insert({
      'user_id': userId,
      'status_type': statusType,
      'content': content,
      'media_path': mediaPath,
      'media_mime': mediaMime,
      'background_color': backgroundColor,
      'is_bold': isBold,
      'caption': caption,
    });
  }

  Future<List<Map<String, dynamic>>> getActiveStatus({String? currentUserId}) async {
    var query = _client
        .from('status')
        .select('id,user_id,status_type,content,media_path,media_mime,background_color,is_bold,created_at,expires_at,caption')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false);

    final res = await query;
    final allStatus = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (currentUserId == null || currentUserId.isEmpty) {
      return allStatus;
    }

    try {
      final privacyRes = await _client
          .from('status_privacy')
          .select('user_id, excluded_user_id');
      
      final exclusions = <String, Set<String>>{};
      for (final row in privacyRes) {
        final userId = (row['user_id'] ?? '').toString();
        final excludedId = (row['excluded_user_id'] ?? '').toString();
        exclusions.putIfAbsent(userId, () => {}).add(excludedId);
      }

      return allStatus.where((status) {
        final authorId = (status['user_id'] ?? '').toString();
        if (authorId == currentUserId) return true;
        final excluded = exclusions[authorId]?.contains(currentUserId) ?? false;
        return !excluded;
      }).toList();
    } catch (_) {
      return allStatus;
    }
  }

  Stream<List<Map<String, dynamic>>> getActiveStatusStream({String? currentUserId}) {
    return _client
        .from('status')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final now = DateTime.now().toUtc();
          return rows
              .where((s) {
                final expiresAt = DateTime.tryParse((s['expires_at'] ?? '').toString());
                return expiresAt != null && now.isBefore(expiresAt);
              })
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
  }

  Future<void> deleteStatus(String statusId) async {
    try {
      final status = await _client
          .from('status')
          .select('media_path')
          .eq('id', statusId)
          .maybeSingle();
      if (status != null) {
        final mediaPath = (status['media_path'] ?? '').toString();
        if (mediaPath.isNotEmpty) {
          try {
            await _client.storage.from('chat_media').remove([mediaPath]);
          } catch (_) {}
        }
      }
    } catch (_) {}

    try { await _client.from('status_views').delete().eq('status_id', statusId); } catch (_) {}
    try { await _client.from('status_likes').delete().eq('status_id', statusId); } catch (_) {}
    try { await _client.from('status_replies').delete().eq('status_id', statusId); } catch (_) {}

    await _client.from('status').delete().eq('id', statusId);
  }

  Future<void> markStatusViewed({required String statusId, required String viewerId}) async {
    try {
      await _client.from('status_views').insert({
        'status_id': statusId,
        'viewer_id': viewerId,
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getStatusViews(String statusId) async {
    final res = await _client
        .from('status_views')
        .select('viewer_id,viewed_at,profiles(id,username,display_name)')
        .eq('status_id', statusId)
        .order('viewed_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<String>> getStatusExcludedUsers(String userId) async {
    final res = await _client
        .from('status_privacy')
        .select('excluded_user_id')
        .eq('user_id', userId);
    return (res as List).map((e) => (e['excluded_user_id'] ?? '').toString()).toList();
  }

  Future<void> excludeFromStatus({required String userId, required String excludedUserId}) async {
    await _client.from('status_privacy').insert({
      'user_id': userId,
      'excluded_user_id': excludedUserId,
    });
  }

  Future<void> includeInStatus({required String userId, required String excludedUserId}) async {
    await _client
        .from('status_privacy')
        .delete()
        .eq('user_id', userId)
        .eq('excluded_user_id', excludedUserId);
  }

  // ---- Status Likes ----
  Future<void> likeStatus({required String statusId, required String userId}) async {
    try {
      await _client.from('status_likes').insert({
        'status_id': statusId,
        'user_id': userId,
      });
    } catch (_) {}
  }

  Future<void> unlikeStatus({required String statusId, required String userId}) async {
    await _client
        .from('status_likes')
        .delete()
        .eq('status_id', statusId)
        .eq('user_id', userId);
  }

  Future<bool> isStatusLikedByMe({required String statusId, required String userId}) async {
    final res = await _client
        .from('status_likes')
        .select('id')
        .eq('status_id', statusId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  Future<int> getStatusLikeCount(String statusId) async {
    final res = await _client
        .from('status_likes')
        .select('id')
        .eq('status_id', statusId);
    return (res as List).length;
  }

  Future<List<Map<String, dynamic>>> getStatusLikes(String statusId) async {
    final res = await _client
        .from('status_likes')
        .select('user_id,created_at,profiles(id,username,display_name)')
        .eq('status_id', statusId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---- Status Replies ----
  Future<void> replyToStatus({
    required String statusId,
    required String userId,
    required String content,
    String? statusAuthorId,
  }) async {
    await _client.from('status_replies').insert({
      'status_id': statusId,
      'user_id': userId,
      'content': content,
    });

    if (statusAuthorId != null && statusAuthorId.isNotEmpty && statusAuthorId != userId) {
      await sendMessage(
        senderId: userId,
        receiverId: statusAuthorId,
        content: content,
        messageType: 'text',
      );
    }
  }

  // ---- Group Chat ----
  Future<String> createGroup({
    required String name,
    String? description,
    required List<String> memberIds,
  }) async {
    final u = _client.auth.currentUser;
    if (u == null) throw Exception('Not signed in');

    final groupRes = await _client.from('groups').insert({
      'name': name.trim(),
      'description': description?.trim(),
      'created_by': u.id,
    }).select('id').single();

    final groupId = groupRes['id'] as String;

    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': u.id,
      'role': 'super_admin',
    });

    if (memberIds.isNotEmpty) {
      final memberInserts = memberIds.map((mid) => {
        'group_id': groupId,
        'user_id': mid,
        'role': 'member',
      }).toList();
      await _client.from('group_members').insert(memberInserts);
    }

    return groupId;
  }

  Future<List<Map<String, dynamic>>> getMyGroups() async {
    final res = await _client.rpc('get_my_groups');
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final res = await _client
        .from('group_members')
        .select('user_id,role,joined_at,profiles(id,username,display_name,email)')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> addGroupMember({required String groupId, required String userId}) async {
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
    });
  }

  Future<void> removeGroupMember({required String groupId, required String userId}) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> leaveGroup(String groupId) async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', u.id);
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _client.from('group_messages').delete().eq('group_id', groupId);
    } catch (_) {}
    try {
      await _client.from('group_members').delete().eq('group_id', groupId);
    } catch (_) {}
    await _client.from('groups').delete().eq('id', groupId);
  }

  Future<void> updateGroupInfo({required String groupId, String? name, String? description}) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name.trim();
    if (description != null) patch['description'] = description.trim();
    if (patch.isEmpty) return;
    patch['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('groups').update(patch).eq('id', groupId);
  }

  Future<void> updateGroupSettings({
    required String groupId,
    bool? onlyAdminsCanSend,
    bool? onlyAdminsCanEditInfo,
  }) async {
    final patch = <String, dynamic>{};
    if (onlyAdminsCanSend != null) patch['only_admins_can_send'] = onlyAdminsCanSend;
    if (onlyAdminsCanEditInfo != null) patch['only_admins_can_edit_info'] = onlyAdminsCanEditInfo;
    if (patch.isEmpty) return;
    patch['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('groups').update(patch).eq('id', groupId);
  }

  Future<void> promoteGroupAdmin({required String groupId, required String userId}) async {
    await _client.rpc('promote_group_admin', params: {
      'p_group_id': groupId,
      'p_user_id': userId,
    });
  }

  Future<void> demoteGroupAdmin({required String groupId, required String userId}) async {
    await _client.rpc('demote_group_admin', params: {
      'p_group_id': groupId,
      'p_user_id': userId,
    });
  }

  bool isGroupAdmin(Map<String, dynamic> group, String userId) {
    final memberRole = group['my_role'] ?? 'member';
    return memberRole == 'admin' || memberRole == 'super_admin';
  }

  Stream<List<Map<String, dynamic>>> getGroupMessages(String groupId) {
    return _client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .map((rows) {
          final messages = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          messages.sort((a, b) {
            final aPinned = a['is_pinned'] == true;
            final bPinned = b['is_pinned'] == true;
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;
            return a['created_at'].compareTo(b['created_at']);
          });
          return messages;
        });
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? mediaPath,
    String? mediaMime,
    int? mediaDurationMs,
    String? mediaName,
    int? mediaSizeBytes,
    int? replyToId,
    String? caption,
    bool isRichText = false,
    String? richTextJson,
    bool isForwarded = false,
    String? forwardedFromId,
  }) async {
    DateTime? mediaExpiresAt;
    if (mediaPath != null && mediaPath.isNotEmpty) {
      mediaExpiresAt = DateTime.now().add(mediaAutoDeleteDuration);
    }

    await _client.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'media_path': mediaPath,
      'media_mime': mediaMime,
      'media_duration_ms': mediaDurationMs,
      'media_name': mediaName,
      'media_size_bytes': mediaSizeBytes,
      'reply_to_id': replyToId,
      'caption': caption,
      'media_expires_at': mediaExpiresAt?.toIso8601String(),
      'is_rich_text': isRichText,
      'rich_text_json': richTextJson,
      'is_forwarded': isForwarded,
      'forwarded_from_id': forwardedFromId,
    });

    // [UPDATE #2] Trigger push notification for group members via FCM
    try {
      await _client.functions.invoke('send-push-notification', body: {
        'group_id': groupId,
        'sender_id': senderId,
        'message_type': messageType,
        'content': messageType == 'text' ? content : '[${messageType.capitalize()}]',
        'type': 'group_message',
      });
    } catch (_) {}
  }

  Future<void> deleteGroupMessageForEveryone({required int messageId}) async {
    await _client.from('group_messages').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'message_type': 'deleted',
      'content': '',
      'caption': null,
      'media_path': null,
      'media_mime': null,
      'media_duration_ms': null,
    }).eq('id', messageId);
  }

  // [UPDATE #6] Delete group message for me only
  // Adds user to the deleted_for_users JSON array so only they don't see it
  Future<void> deleteGroupMessageForMe({required int messageId, required String userId}) async {
    try {
      // Get current deleted_for_users
      final msg = await _client.from('group_messages').select('deleted_for_users').eq('id', messageId).maybeSingle();
      List<dynamic> deletedForUsers = [];
      if (msg != null && msg['deleted_for_users'] != null) {
        try {
          deletedForUsers = List<dynamic>.from(msg['deleted_for_users'] as List);
        } catch (_) {}
      }
      // Add this user if not already in the list
      if (!deletedForUsers.contains(userId)) {
        deletedForUsers.add(userId);
      }
      await _client.from('group_messages').update({
        'deleted_for_users': deletedForUsers,
      }).eq('id', messageId);
    } catch (e) {
      debugPrint('deleteGroupMessageForMe failed: $e');
    }
  }

  Future<void> pinGroupMessage({required int messageId, required bool pinned}) async {
    await _client.from('group_messages').update({'is_pinned': pinned}).eq('id', messageId);
  }

  Future<void> editGroupMessage({required int messageId, required String newContent}) async {
    await _client.from('group_messages').update({
      'content': newContent,
      'edited_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  Future<void> starGroupMessage({required int messageId, required bool starred}) async {
    await _client.from('group_messages').update({'is_starred': starred}).eq('id', messageId);
  }

  // ---- Export Chat as TXT ----
  Future<String> exportChatAsTxt({
    required String currentUserId,
    required String otherUserId,
    required String otherDisplayName,
  }) async {
    final messages = await fetchConversationOnce(currentUserId, otherUserId);
    final myProfile = await getProfile(currentUserId);
    final myName = myProfile?['display_name'] ?? myProfile?['username'] ?? 'Me';

    final buffer = StringBuffer();
    buffer.writeln('CDN-NETCHAT Chat Export');
    buffer.writeln('Exported: ${DateTime.now().toLocal()}');
    buffer.writeln('Chat between: $myName and $otherDisplayName');
    buffer.writeln('${'=' * 50}');
    buffer.writeln();

    for (final msg in messages) {
      final isMe = msg['sender_id'] == currentUserId;
      final deletedForMe = isMe
          ? (msg['deleted_for_sender'] == true)
          : (msg['deleted_for_receiver'] == true);
      if (deletedForMe && (msg['message_type'] ?? '') != 'deleted') continue;

      final senderName = isMe ? myName : otherDisplayName;
      final time = DateTime.tryParse((msg['created_at'] ?? '').toString());
      final timeStr = time != null
          ? '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : '';

      final type = (msg['message_type'] ?? 'text').toString();

      if (type == 'deleted') {
        buffer.writeln('[$timeStr] $senderName: [Message deleted]');
      } else if (type == 'image') {
        final caption = (msg['caption'] ?? '').toString();
        buffer.writeln('[$timeStr] $senderName: [Image]$caption');
      } else if (type == 'audio') {
        buffer.writeln('[$timeStr] $senderName: [Voice note]');
      } else if (type == 'file') {
        final fileName = (msg['media_name'] ?? 'File').toString();
        buffer.writeln('[$timeStr] $senderName: [File: $fileName]');
      } else {
        final content = (msg['content'] ?? '').toString();
        buffer.writeln('[$timeStr] $senderName: $content');
      }
    }

    buffer.writeln();
    buffer.writeln('${'=' * 50}');
    buffer.writeln('End of chat export');

    return buffer.toString();
  }

  // ---- Admin RPCs ----
  Future<List<Map<String, dynamic>>> adminListProfiles({required String secret}) async {
    final res = await _client.rpc('admin_list_profiles', params: {'p_secret': secret});
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> adminListAuthEvents({required String secret, int limit = 200}) async {
    final res = await _client.rpc('admin_list_auth_events', params: {'p_secret': secret, 'p_limit': limit});
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> adminGrantPremium({required String secret, required String userId, int days = 30}) async {
    await _client.rpc('admin_grant_premium', params: {'p_secret': secret, 'p_user_id': userId, 'p_days': days});
  }

  Future<void> adminSetVpnConfig({required String secret, required String shareLink}) async {
    await _client.rpc('admin_set_vpn_config', params: {'p_secret': secret, 'p_share_link': shareLink});
  }

  Future<void> adminRevokePremium({required String secret, required String userId}) async {
    await _client.rpc('admin_revoke_premium', params: {'p_secret': secret, 'p_user_id': userId});
  }

  Future<void> adminSetUserBlocked({
    required String secret,
    required String userId,
    required bool blocked,
    String? reason,
  }) async {
    await _client.rpc('admin_set_user_blocked', params: {
      'p_secret': secret,
      'p_user_id': userId,
      'p_blocked': blocked,
      'p_reason': reason,
    });
  }
}

/// String extension for capitalize
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
