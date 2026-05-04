import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/supabase_service.dart';
import 'local_message.dart';

/// WhatsApp-like local message store (Isar) + Supabase sync.
class LocalChatStore {
  LocalChatStore({SupabaseService? supabaseService}) : _supabase = supabaseService ?? SupabaseService();

  final SupabaseService _supabase;
  Isar? _isar;

  Future<Isar> _db() async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LocalMessageSchema],
      directory: p.join(dir.path, 'isar_db'),
      inspector: false,
    );
    return _isar!;
  }

  Future<void> upsertFromRemote({
    required String ownerUserId,
    required String otherUserId,
    required Map<String, dynamic> m,
  }) async {
    final isar = await _db();

    final remoteId = int.tryParse((m['id'] ?? '').toString());
    if (remoteId == null) return;

    await isar.writeTxn(() async {
      final existing = await isar.localMessages.filter().remoteIdEqualTo(remoteId).findFirst();
      final msg = existing ?? LocalMessage();

      msg.remoteId = remoteId;
      msg.ownerUserId = ownerUserId;
      msg.otherUserId = otherUserId;

      msg.senderId = (m['sender_id'] ?? '').toString();
      msg.receiverId = (m['receiver_id'] ?? '').toString();
      msg.messageType = (m['message_type'] ?? 'text').toString();
      msg.content = (m['content'] ?? '').toString();

      msg.mediaPath = m['media_path']?.toString();
      msg.mediaMime = m['media_mime']?.toString();
      msg.mediaDurationMs = m['media_duration_ms'] == null ? null : int.tryParse(m['media_duration_ms'].toString());
      msg.mediaName = m['media_name']?.toString();
      msg.mediaSizeBytes = m['media_size_bytes'] == null ? null : int.tryParse(m['media_size_bytes'].toString());

      msg.caption = m['caption']?.toString();
      msg.replyToRemoteId = m['reply_to_id'] == null ? null : int.tryParse(m['reply_to_id'].toString());

      final ca = DateTime.tryParse((m['created_at'] ?? '').toString());
      if (ca != null) msg.createdAt = ca.toUtc();

      msg.editedAt = m['edited_at'] == null ? null : DateTime.tryParse(m['edited_at'].toString())?.toUtc();
      msg.deletedAt = m['deleted_at'] == null ? null : DateTime.tryParse(m['deleted_at'].toString())?.toUtc();

      msg.isRead = m['is_read'] == true;
      msg.isLiked = m['is_liked'] == true;

      // Reactions - stored as JSON string
      if (m['reactions'] != null) {
        msg.reactions = m['reactions'] is Map
            ? jsonEncode(m['reactions'])
            : m['reactions'].toString();
      }

      // Pinned
      msg.isPinned = m['is_pinned'] == true;

      // Media expiry
      msg.mediaExpiresAt = m['media_expires_at'] == null
          ? null
          : DateTime.tryParse(m['media_expires_at'].toString())?.toUtc();

      msg.expiresAt = m['expires_at'] == null ? null : DateTime.tryParse(m['expires_at'].toString())?.toUtc();
      msg.viewOnce = m['view_once'] == true;
      msg.viewedBySender = m['viewed_by_sender'] == true;
      msg.viewedByReceiver = m['viewed_by_receiver'] == true;

      msg.deletedForSender = m['deleted_for_sender'] == true;
      msg.deletedForReceiver = m['deleted_for_receiver'] == true;

      await isar.localMessages.put(msg);
    });
  }

  Stream<List<LocalMessage>> watchConversation({
    required String ownerUserId,
    required String otherUserId,
  }) async* {
    yield const <LocalMessage>[];

    try {
      final isar = await _db();
      yield* isar.localMessages
          .filter()
          .ownerUserIdEqualTo(ownerUserId)
          .otherUserIdEqualTo(otherUserId)
          .sortByCreatedAt()
          .watch(fireImmediately: true);
    } catch (_) {
      yield const <LocalMessage>[];
    }
  }

  /// One-time hydrate from Supabase into local store.
  Future<void> hydrateConversation({required String ownerUserId, required String otherUserId}) async {
    final remote = await _supabase.fetchConversationOnce(ownerUserId, otherUserId);
    for (final m in remote) {
      await upsertFromRemote(ownerUserId: ownerUserId, otherUserId: otherUserId, m: m);
    }
  }

  /// Restore local store from a backup message list (messages.json).
  Future<void> restoreFromBackup({required String ownerUserId, required List<dynamic> messages}) async {
    for (final raw in messages) {
      if (raw is! Map) continue;
      final m = raw.cast<String, dynamic>();

      final sender = (m['sender_id'] ?? '').toString();
      final receiver = (m['receiver_id'] ?? '').toString();
      if (sender.isEmpty || receiver.isEmpty) continue;
      final otherUserId = (sender == ownerUserId) ? receiver : sender;

      await upsertFromRemote(ownerUserId: ownerUserId, otherUserId: otherUserId, m: m);
    }
  }

  /// Get unread count for a conversation
  Future<int> getUnreadCount({required String ownerUserId, required String otherUserId}) async {
    final isar = await _db();
    final unread = await isar.localMessages
        .filter()
        .ownerUserIdEqualTo(ownerUserId)
        .otherUserIdEqualTo(otherUserId)
        .and()
        .isReadEqualTo(false)
        .and()
        .senderIdEqualTo(otherUserId)
        .findAll();
    return unread.length;
  }

  /// Mark all messages as read locally
  Future<void> markAllAsRead({required String ownerUserId, required String otherUserId}) async {
    final isar = await _db();
    await isar.writeTxn(() async {
      final unread = await isar.localMessages
          .filter()
          .ownerUserIdEqualTo(ownerUserId)
          .otherUserIdEqualTo(otherUserId)
          .and()
          .isReadEqualTo(false)
          .and()
          .senderIdEqualTo(otherUserId)
          .findAll();
      for (final msg in unread) {
        msg.isRead = true;
        await isar.localMessages.put(msg);
      }
    });
  }
}
