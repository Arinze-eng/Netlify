import 'package:isar/isar.dart';

part 'local_message.g.dart';

@collection
class LocalMessage {
  Id id = Isar.autoIncrement;

  /// Supabase message id (BIGINT) if known
  @Index(unique: true, replace: true)
  int? remoteId;

  @Index()
  late String ownerUserId;

  @Index()
  late String otherUserId;

  late String senderId;
  late String receiverId;

  late String messageType; // text | emoji | image | voice | audio | file | deleted
  late String content;

  String? mediaPath;
  String? mediaMime;
  int? mediaDurationMs;

  String? mediaName;
  int? mediaSizeBytes;

  String? localMediaPath; // Local cached path (WhatsApp-like)

  String? caption;
  int? replyToRemoteId;

  DateTime createdAt = DateTime.now().toUtc();
  DateTime? editedAt;
  DateTime? deletedAt;

  bool isRead = false;
  bool isLiked = false;

  // Reactions stored as JSON string: {"userId": "emoji"}
  String? reactions;

  // Pinned message
  bool isPinned = false;

  // Media auto-delete tracking
  DateTime? mediaExpiresAt;

  DateTime? expiresAt;
  bool viewOnce = false;
  bool viewedBySender = false;
  bool viewedByReceiver = false;

  bool deletedForSender = false;
  bool deletedForReceiver = false;
}
