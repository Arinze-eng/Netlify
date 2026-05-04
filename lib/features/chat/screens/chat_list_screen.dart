import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../../../services/supabase_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/drive_backup_service.dart';
import '../../../services/vpn_manager.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../local_db/local_chat_store.dart';
import '../../../screens/admin_screen.dart';

import 'chat_room_screen.dart';
import 'group_chat_room_screen.dart';
import 'create_group_screen.dart';
import '../../payment/screens/payment_screen.dart';
import '../../status/screens/status_screen.dart';
import '../../vpn_ui/widgets/vpn_card.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  final _uuidController = TextEditingController();

  Map<String, dynamic>? _profile;

  List<Map<String, dynamic>> _threads = [];
  bool _threadsLoading = false;

  List<Map<String, dynamic>> _groups = [];
  bool _groupsLoading = false;

  List<Map<String, dynamic>> _discoverUsers = [];
  bool _discoverLoading = false;
  final _discoverSearchController = TextEditingController();

  bool _isInitializing = true;
  String? _initError;

  bool _hasAccess = true;
  Timer? _lastSeenTimer;

  StreamSubscription<List<Map<String, dynamic>>>? _incomingSub;
  int _lastIncomingMessageId = 0;
  bool _isInChatRoom = false;

  StreamSubscription? _threadRefreshSub;

  StreamSubscription<List<Map<String, dynamic>>>? _callSignalSub;
  final Set<String> _seenCallSignalIds = {};

  // Users with active status (for green ring indicator)
  Set<String> _usersWithActiveStatus = {};

  // Tab controller for Chats/Status/Calls
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fix: Add listener so FAB visibility updates when tab changes
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _initApp();
    _startIncomingMessageNotifications();
    _listenForIncomingCalls();

    _lastSeenTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final user = _supabaseService.currentUser;
      if (user != null) {
        _supabaseService.updateLastSeen(user.id);
      }
    });
  }

  @override
  void dispose() {
    _lastSeenTimer?.cancel();
    _incomingSub?.cancel();
    _threadRefreshSub?.cancel();
    _callSignalSub?.cancel();
    _uuidController.dispose();
    _discoverSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _listenForIncomingCalls() {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    _callSignalSub = _supabaseService.streamCallSignals(user.id).listen((signals) {
      if (!mounted || _isInChatRoom) return;
      for (final s in signals) {
        final sigId = (s['id'] ?? '').toString();
        if (_seenCallSignalIds.contains(sigId)) continue;
        _seenCallSignalIds.add(sigId);

        final type = (s['type'] ?? '').toString();
        if (type == 'call_offer') {
          final payload = s['payload'] as Map<String, dynamic>?;
          final isVideo = payload?['is_video'] == true;
          final fromId = (s['from_id'] ?? '').toString();

          NotificationService.showIncomingCallNotification(
            title: isVideo ? 'Incoming Video Call' : 'Incoming Call',
            body: 'Someone is calling you on CDN-NETCHAT',
            payload: fromId,
          );
        }
      }
    });
  }

  Future<void> _initApp() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final user = _supabaseService.currentUser;

      if (user == null) {
        setState(() {
          _isInitializing = false;
          _initError = 'No active session. Please sign in again.';
        });
        return;
      }

      final profile = await _supabaseService.getProfile(user.id);
      final access = await _supabaseService.checkAccessStatus(user.id);

      if (profile != null && profile['is_blocked'] == true) {
        await _supabaseService.signOut();
        if (mounted) {
          final reason = (profile['blocked_reason'] ?? 'Your account has been blocked by admin.').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(reason), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)),
          );
        }
        return;
      }

      final usernameFromMeta = (user.userMetadata?['username'] ?? '').toString();
      final displayNameFromMeta = (user.userMetadata?['display_name'] ?? '').toString();
      final fallbackProfile = {
        'id': user.id,
        'email': user.email,
        'username': usernameFromMeta.isNotEmpty ? usernameFromMeta : user.id.substring(0, 8).toUpperCase(),
        'display_name': displayNameFromMeta,
      };

      final hasAccess = access['hasAccess'] == true;

      setState(() {
        _profile = profile ?? fallbackProfile;
        _hasAccess = hasAccess;
      });

      // Enforce subscription when entering chat list.
      // VPN starts immediately on app open, but if user has no access we stop VPN
      // and redirect to Payment.
      if (!hasAccess) {
        try { await VpnManager.instance.stop(); } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription required to use chat.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PaymentScreen()),
          );
        }
        return;
      }

      _supabaseService.updateLastSeen(user.id);

      await Future.wait([
        _refreshThreads(),
        _loadDiscoverUsers(),
        _loadGroups(),
        _loadActiveStatusUsers(),
      ]);

      _startThreadRefreshListener();

      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  /// Load users who have active status (for green ring indicator)
  Future<void> _loadActiveStatusUsers() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;
      final allStatus = await _supabaseService.getActiveStatus(currentUserId: user.id);
      final activeUserIds = <String>{};
      for (final s in allStatus) {
        final userId = (s['user_id'] ?? '').toString();
        if (userId != user.id) {
          activeUserIds.add(userId);
        }
      }
      if (mounted) {
        setState(() => _usersWithActiveStatus = activeUserIds);
      }
    } catch (_) {}
  }

  void _startThreadRefreshListener() {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    _threadRefreshSub?.cancel();
    _threadRefreshSub = _supabaseService.streamIncomingMessages(user.id).listen((msgs) {
      if (mounted && !_isInChatRoom) {
        _refreshThreads();
      }
    });
  }

  void _startIncomingMessageNotifications() {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    _incomingSub?.cancel();
    _incomingSub = _supabaseService.streamIncomingMessages(user.id).listen((msgs) {
      if (!mounted) return;
      if (msgs.isEmpty) return;

      final last = msgs.last;
      final id = int.tryParse((last['id'] ?? 0).toString()) ?? 0;
      if (id <= _lastIncomingMessageId) return;

      _lastIncomingMessageId = id;

      final isUnread = (last['is_read'] == false);
      if (!isUnread || _isInChatRoom) return;

      _refreshThreads();

      final senderId = (last['sender_id'] ?? '').toString();
      final type = (last['message_type'] ?? 'text').toString();
      final body = switch (type) {
        'image' => '[Image]',
        'audio' => '[Voice note]',
        'video' => '[Video]',
        'file' => '[File]',
        'emoji' => (last['content'] ?? '').toString(),
        _ => (last['content'] ?? '').toString(),
      };

      final senderProfile = _discoverUsers.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p != null && (p['id']?.toString() == senderId),
            orElse: () => null,
          );

      final senderName = (senderProfile == null)
          ? 'New message'
          : (((senderProfile['display_name'] ?? '') as String).trim().isNotEmpty
              ? senderProfile['display_name']
              : senderProfile['username']);

      NotificationService.showIncomingMessageNotification(
        title: senderName.toString(),
        body: body.isEmpty ? 'New message' : body,
        payload: senderId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$senderName: $body'),
          duration: const Duration(seconds: 4),
          action: (senderProfile == null)
              ? null
              : SnackBarAction(
                  label: 'Open',
                  onPressed: () {
                    _openChatWith(senderProfile);
                  },
                ),
        ),
      );
    });
  }

  Future<void> _refreshThreads() async {
    try {
      if (mounted) setState(() => _threadsLoading = true);
      final data = await _supabaseService.getChatThreads();
      if (!mounted) return;
      setState(() => _threads = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _threadsLoading = false);
    }
  }

  Future<void> _loadGroups() async {
    try {
      if (mounted) setState(() => _groupsLoading = true);
      final data = await _supabaseService.getMyGroups();
      if (!mounted) return;
      setState(() => _groups = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _groupsLoading = false);
    }
  }

  Future<void> _loadDiscoverUsers() async {
    try {
      if (mounted) setState(() => _discoverLoading = true);
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final data = await _supabaseService.listProfiles();
      if (!mounted) return;
      setState(() {
        _discoverUsers = data.where((p) => p['id'] != user.id).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _discoverLoading = false);
    }
  }

  void _openChatWith(Map<String, dynamic> otherUser) {
    if (_profile == null) return;

    if (!_hasAccess) {
      _showPaymentDialog();
      return;
    }

    _isInChatRoom = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          otherUser: otherUser,
          currentUser: _profile!,
        ),
      ),
    ).then((_) {
      _isInChatRoom = false;
      _refreshThreads();
      _loadDiscoverUsers();
    });
  }

  void _openGroupChat(Map<String, dynamic> group) {
    if (_profile == null) return;

    _isInChatRoom = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatRoomScreen(
          group: group,
          currentUser: _profile!,
        ),
      ),
    ).then((_) {
      _isInChatRoom = false;
      _loadGroups();
      _refreshThreads();
    });
  }

  // ---- Delete chat on long press ----
  void _showDeleteChatDialog(Map<String, dynamic> thread) {
    final otherName = (thread['other_display_name'] ?? thread['other_username'] ?? 'this user').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Chat?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete your chat with $otherName? This will remove the conversation from your chat list.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final otherId = (thread['other_user_id'] ?? thread['other_id'] ?? '').toString();
              if (otherId.isEmpty) return;

              try {
                await _supabaseService.deleteChatThread(otherId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat with $otherName deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _refreshThreads();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete chat: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDiscoverBottomSheet() {
    _discoverSearchController.text = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = _discoverSearchController.text.trim().toUpperCase();
            final filtered = _discoverUsers.where((u) {
              final username = (u['username'] ?? '').toString().toUpperCase();
              final email = (u['email'] ?? '').toString().toUpperCase();
              final name = (u['display_name'] ?? '').toString().toUpperCase();
              return q.isEmpty || username.contains(q) || email.contains(q) || name.contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Discover Users (UUID)',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _discoverSearchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by UUID or email…',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_discoverLoading)
                      const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.08)),
                          itemBuilder: (context, i) {
                            final u = filtered[i];
                            final userId = (u['id'] ?? '').toString();
                            final hasStatus = _usersWithActiveStatus.contains(userId);
                            final name = ((u['display_name'] ?? '') as String).trim();
                            final letter = (name.isNotEmpty ? name : (u['username'] ?? 'U'))[0].toUpperCase();

                            return ListTile(
                              dense: true,
                              leading: hasStatus
                                  ? CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF25D366),
                                      child: CircleAvatar(
                                        radius: 17,
                                        backgroundColor: const Color(0xFF0B141A),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: const Color(0xFF6366F1),
                                          child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: const Color(0xFF6366F1),
                                      child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    ),
                              title: Text(
                                name.isNotEmpty
                                    ? '$name  (${u['username'] ?? ''})'
                                    : (u['username'] ?? ''),
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                u['email'] ?? '',
                                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF6366F1)),
                              onTap: () {
                                Navigator.pop(context);
                                _openChatWith(u);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startChat() async {
    final chatUuid = _uuidController.text.trim().toUpperCase();
    if (chatUuid.isEmpty) return;

    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still loading your profile. Please try again.')),
      );
      return;
    }

    if (!_hasAccess) {
      _showPaymentDialog();
      return;
    }

    final targetProfile = await _supabaseService.getProfileByChatUuid(chatUuid);
    if (targetProfile != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              otherUser: targetProfile,
              currentUser: _profile!,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User UUID not found')),
        );
      }
    }
  }

  void _showPaymentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentScreen()),
    ).then((value) {
      if (value == true) _initApp();
    });
  }

  Future<void> _shareChatBackup() async {
    try {
      if (_profile == null) return;
      final userId = _profile!['id'] as String;

      final threads = await _supabaseService.getChatThreads();
      final allMessages = <Map<String, dynamic>>[];
      final contacts = <Map<String, dynamic>>[];

      for (final t in threads) {
        final otherId = (t['other_user_id'] ?? t['other_id'] ?? '').toString();
        if (otherId.isEmpty) continue;

        contacts.add({
          'id': otherId,
          'username': t['other_username'] ?? t['username'] ?? '',
          'display_name': t['other_display_name'] ?? '',
          'email': t['other_email'] ?? t['email'] ?? '',
        });

        final convo = await _supabaseService.fetchConversationOnce(userId, otherId);
        allMessages.addAll(convo);
      }

      // Build ZIP archive with messages.json + cached media
      final archive = Archive();
      final jsonBytes = utf8.encode(jsonEncode({
        'version': '3.1.0',
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'user_id': userId,
        'contacts': contacts,
        'messages': allMessages,
      }));
      archive.addFile(ArchiveFile('messages.json', jsonBytes.length, jsonBytes));

      // Include cached media files in the backup
      try {
        final docs = await getApplicationDocumentsDirectory();
        final cacheDir = Directory(p.join(docs.path, 'chat_media_cache'));
        if (await cacheDir.exists()) {
          await for (final ent in cacheDir.list(recursive: true, followLinks: false)) {
            if (ent is! File) continue;
            final rel = p.relative(ent.path, from: cacheDir.path);
            final bytes = await ent.readAsBytes();
            archive.addFile(ArchiveFile(p.join('media', rel), bytes.length, bytes));
          }
        }
      } catch (_) {
        // Non-blocking: include messages even if media backup fails
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('Failed to create backup ZIP');

      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'cdn-netchat-backup-${DateTime.now().millisecondsSinceEpoch}.zip');
      await File(filePath).writeAsBytes(zipData);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'CDN-NETCHAT Chat Backup'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportAllChatsAsTxt() async {
    try {
      if (_profile == null) return;
      final userId = _profile!['id'] as String;
      final myName = (_profile!['display_name'] ?? _profile!['username'] ?? 'Me')?.toString() ?? 'Me';

      final threads = await _supabaseService.getChatThreads();
      final buffer = StringBuffer();

      buffer.writeln('CDN-NETCHAT Full Chat Export');
      buffer.writeln('Exported: ${DateTime.now().toLocal()}');
      buffer.writeln('User: $myName');
      buffer.writeln('${'=' * 60}');
      buffer.writeln();

      for (final t in threads) {
        final otherId = (t['other_user_id'] ?? t['other_id'] ?? '').toString();
        if (otherId.isEmpty) continue;

        final otherName = (t['other_display_name'] ?? t['other_username'] ?? 'User').toString();

        buffer.writeln('--- Chat with $otherName ---');
        buffer.writeln();

        final messages = await _supabaseService.fetchConversationOnce(userId, otherId);
        for (final msg in messages) {
          final isMe = msg['sender_id'] == userId;
          final deletedForMe = isMe
              ? (msg['deleted_for_sender'] == true)
              : (msg['deleted_for_receiver'] == true);
          if (deletedForMe && (msg['message_type'] ?? '') != 'deleted') continue;

          final senderName = isMe ? myName : otherName;
          final time = DateTime.tryParse((msg['created_at'] ?? '').toString());
          final timeStr = time != null
              ? '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
              : '';
          final type = (msg['message_type'] ?? 'text').toString();

          if (type == 'deleted') {
            buffer.writeln('[$timeStr] $senderName: [Message deleted]');
          } else if (type == 'image') {
            buffer.writeln('[$timeStr] $senderName: [Image]');
          } else if (type == 'audio') {
            buffer.writeln('[$timeStr] $senderName: [Voice note]');
          } else if (type == 'file') {
            buffer.writeln('[$timeStr] $senderName: [File: ${msg['media_name'] ?? 'File'}]');
          } else {
            buffer.writeln('[$timeStr] $senderName: ${msg['content'] ?? ''}');
          }
        }

        buffer.writeln();
        buffer.writeln('${'-' * 40}');
        buffer.writeln();
      }

      buffer.writeln('${'=' * 60}');
      buffer.writeln('End of export');

      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'cdn-netchat-export-${DateTime.now().millisecondsSinceEpoch}.txt');
      await File(filePath).writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'CDN-NETCHAT Chat Export (TXT)'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _restoreChatFromBackup() async {
    try {
      // Use FilePicker to let user select any .json or .zip file from anywhere on device
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: ['json', 'zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access the selected file'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Restoring backup...'),
              ],
            ),
            duration: Duration(seconds: 30),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
      }

      final userId = _profile?['id'] as String?;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to restore backup'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      List<dynamic> messages = [];
      List<dynamic> contacts = [];

      if (filePath.endsWith('.zip')) {
        // Handle ZIP backup (from Google Drive or Share backup with media)
        final bytes = await File(filePath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Extract messages.json from ZIP
        try {
          final msgFile = archive.files.firstWhere((f) => f.isFile && f.name == 'messages.json');
          final raw = utf8.decode(msgFile.content as List<int>);
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          messages = (decoded['messages'] as List?) ?? [];
          contacts = (decoded['contacts'] as List?) ?? [];

          // Restore media files from ZIP
          final docs = await getApplicationDocumentsDirectory();
          final cacheDir = Directory(p.join(docs.path, 'chat_media_cache'));
          if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

          for (final file in archive.files) {
            if (!file.isFile || !file.name.startsWith('media/')) continue;
            final rel = file.name.substring('media/'.length);
            final target = File(p.join(cacheDir.path, rel));
            await target.parent.create(recursive: true);
            await target.writeAsBytes(file.content as List<int>, flush: true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid backup ZIP: ${e.toString()}'), backgroundColor: Colors.redAccent),
            );
          }
          return;
        }
      } else {
        // Handle JSON backup
        final backup = jsonDecode(await File(filePath).readAsString()) as Map<String, dynamic>;
        messages = (backup['messages'] as List?) ?? [];
        contacts = (backup['contacts'] as List?) ?? [];
      }

      if (messages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No messages found in backup'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Restore messages into local store
      final store = LocalChatStore(supabaseService: _supabaseService);
      await store.restoreFromBackup(ownerUserId: userId, messages: messages);

      await _refreshThreads();
      await _loadDiscoverUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Restored ${messages.length} messages and ${contacts.length} contacts'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<String?> _pickBackupFile() async {
    try {
      // Use FilePicker instead of hardcoded directory
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.single.path;
      }
      return null;
    } catch (_) {
      // Fallback: check local backups directory
      try {
        final dir = await getApplicationDocumentsDirectory();
        final backupDir = Directory(p.join(dir.path, 'backups'));
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        final files = await backupDir.list().where((f) => f.path.endsWith('.json')).toList();
        if (files.isNotEmpty) return files.first.path;
        return null;
      } catch (_) {
        return null;
      }
    }
  }

  // ---- Telegram-style Drawer ----
  Widget _buildDrawer() {
    final displayName = _profile?['display_name'] ?? '';
    final username = _profile?['username'] ?? '';
    final email = _profile?['email'] ?? '';

    return Drawer(
      backgroundColor: const Color(0xFF0F1F28),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (displayName.isNotEmpty ? displayName : username)[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName.isNotEmpty ? displayName : username,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hasAccess ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _hasAccess ? 'ACTIVE' : 'EXPIRED',
                    style: GoogleFonts.poppins(
                      color: _hasAccess ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.vpn_lock_rounded, color: Color(0xFF2AABEE)),
            title: Text('Offline Mode VPN(60MB)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showVpnBottomSheet();
            },
          ),

          ListTile(
            leading: const Icon(Icons.group_add_rounded, color: Color(0xFF2AABEE)),
            title: Text('New Group', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              if (_profile == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateGroupScreen(currentUser: _profile!),
                ),
              ).then((_) {
                _loadGroups();
                _refreshThreads();
              });
            },
          ),

          // Starred Messages
          ListTile(
            leading: const Icon(Icons.star_rounded, color: Colors.amber),
            title: Text('Starred Messages', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showStarredMessages();
            },
          ),

          ListTile(
            leading: const Icon(Icons.backup_rounded, color: Color(0xFF2AABEE)),
            title: Text('Chat Backup', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showBackupRestoreSheet();
            },
          ),

          ListTile(
            leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber),
            title: Text('Admin Panel', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.stars_rounded, color: Colors.amber),
            title: Text('Premium', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showPaymentDialog();
            },
          ),

          const Divider(color: Colors.white12),

          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded, color: Colors.white70),
            title: Text('Privacy', style: GoogleFonts.poppins(color: Colors.white70)),
            onTap: () {
              Navigator.pop(context);
              _showPrivacySettings();
            },
          ),

          ListTile(
            leading: const Icon(Icons.search_rounded, color: Colors.white70),
            title: Text('Discover Users', style: GoogleFonts.poppins(color: Colors.white70)),
            onTap: () {
              Navigator.pop(context);
              _showDiscoverBottomSheet();
            },
          ),

          const Divider(color: Colors.white12),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text('Logout', style: GoogleFonts.poppins(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context);
              VpnManager.instance.stopByUser();
              VpnManager.instance.resetAutoStart();
              await _supabaseService.signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showStarredMessages() async {
    if (_profile == null) return;
    try {
      final starred = await _supabaseService.getStarredMessages(_profile!['id']);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0F2027),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 14),
                Text('Starred Messages', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                if (starred.isEmpty)
                  Center(child: Text('No starred messages', style: GoogleFonts.poppins(color: Colors.white54)))
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: starred.map((m) {
                        final content = (m['content'] ?? '').toString();
                        final type = (m['message_type'] ?? 'text').toString();
                        final time = DateTime.tryParse((m['created_at'] ?? '').toString());
                        return ListTile(
                          leading: Icon(
                            type == 'image' ? Icons.image_rounded :
                            type == 'audio' ? Icons.mic_rounded :
                            type == 'file' ? Icons.insert_drive_file_rounded :
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          title: Text(content.isEmpty ? '[$type]' : content, style: GoogleFonts.poppins(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(time != null ? '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}' : '', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  void _showBackupRestoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: 14),
              Text('Chat Backup & Restore',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Text(
                'Share your entire chat history and contacts, or restore from a backup file.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _exportAllChatsAsTxt,
                  icon: const Icon(Icons.description_rounded),
                  label: Text('Export as TXT', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _shareChatBackup,
                  icon: const Icon(Icons.share_rounded),
                  label: Text('Share Chat Backup (JSON)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _restoreChatFromBackup,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text('Restore Chat Backup', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AABEE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVpnBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: VpnCard(),
            ),
          );
        },
      ),
    );
  }

  void _showPrivacySettings() {
    bool hideLastSeen = false;
    bool hideReadReceipts = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            _supabaseService.getMyPrivacySettings().then((settings) {
              if (settings != null) {
                setModalState(() {
                  hideLastSeen = settings['hide_last_seen'] == true;
                  hideReadReceipts = settings['hide_read_receipts'] == true;
                });
              }
            });

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 14),
                    Text('Privacy Settings',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      value: hideLastSeen,
                      onChanged: (v) async {
                        await _supabaseService.updatePrivacySettings(hideLastSeen: v);
                        setModalState(() => hideLastSeen = v);
                      },
                      title: Text('Hide Last Seen', style: GoogleFonts.poppins(color: Colors.white)),
                      subtitle: Text('Others won\'t see when you were last online',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      activeColor: const Color(0xFF6366F1),
                    ),
                    SwitchListTile(
                      value: hideReadReceipts,
                      onChanged: (v) async {
                        await _supabaseService.updatePrivacySettings(hideReadReceipts: v);
                        setModalState(() => hideReadReceipts = v);
                      },
                      title: Text('Hide Read Receipts', style: GoogleFonts.poppins(color: Colors.white)),
                      subtitle: Text('Others won\'t see if you read their messages',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('CDN-NETCHAT', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Chats', icon: Icon(Icons.chat_rounded, size: 20)),
            Tab(text: 'Status', icon: Icon(Icons.update_rounded, size: 20)),
            Tab(text: 'Calls', icon: Icon(Icons.call_rounded, size: 20)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF6366F1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _showDiscoverBottomSheet,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isInitializing
          ? _buildLoadingState()
          : (_initError != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatsTab(),
                    _profile != null ? StatusScreen(currentUser: _profile!) : const SizedBox.shrink(),
                    _buildCallsTab(),
                  ],
                )),
      floatingActionButton: _tabController.index == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'group_fab',
                  mini: true,
                  onPressed: () {
                    if (_profile == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateGroupScreen(currentUser: _profile!),
                      ),
                    ).then((_) {
                      _loadGroups();
                      _refreshThreads();
                    });
                  },
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.group_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'chat_fab',
                  onPressed: _showDiscoverBottomSheet,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Icon(Icons.chat_rounded, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        _buildProfileHeader(),
        _buildUuidInput(),
        Expanded(
          child: _buildChatHistory(),
        ),
      ],
    );
  }

  Widget _buildCallsTab() {
    if (_profile == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabaseService.streamCallHistory(_profile!['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final calls = snapshot.data!;
        if (calls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_end_rounded, color: Colors.white.withOpacity(0.1), size: 80),
                const SizedBox(height: 16),
                Text('No call history yet', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: calls.length,
          separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.08)),
          itemBuilder: (context, index) {
            final call = calls[index];
            final isMe = call['caller_id'] == _profile!['id'];
            final otherId = isMe ? call['receiver_id'] : call['caller_id'];
            final callType = (call['call_type'] ?? 'audio').toString();
            final status = (call['status'] ?? 'missed').toString();
            final duration = call['duration_seconds'] as int?;
            final startedAt = DateTime.tryParse((call['started_at'] ?? '').toString());

            // Find other user name from discover
            final otherUser = _discoverUsers.cast<Map<String, dynamic>?>().firstWhere(
              (p) => p != null && p['id']?.toString() == otherId.toString(),
              orElse: () => null,
            );
            final name = otherUser != null
                ? ((otherUser['display_name'] ?? '').toString().trim().isNotEmpty
                    ? otherUser['display_name']
                    : otherUser['username'] ?? 'Unknown')
                : 'Unknown';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: status == 'missed' ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF6366F1),
                child: Icon(
                  callType == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                  color: Colors.white, size: 20,
                ),
              ),
              title: Text(name.toString(), style: GoogleFonts.poppins(color: status == 'missed' ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${isMe ? 'Outgoing' : 'Incoming'} ${callType == 'video' ? 'video' : 'audio'} call'
                '${duration != null && status == 'completed' ? ' • ${duration}s' : ''}'
                '${status == 'missed' ? ' • Missed' : ''}',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: startedAt != null ? Text(
                '${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
              ) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _initError ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initApp,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_profile == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                ((_profile?['username'] ?? '') as String).isNotEmpty
                    ? ((_profile?['username'] ?? '') as String)[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Chat UUID',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    (_profile?['username'] ?? 'User') as String,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _hasAccess ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _hasAccess ? Colors.green : Colors.orange),
              ),
              child: Text(
                _hasAccess ? 'ACTIVE' : 'EXPIRED',
                style: GoogleFonts.poppins(
                  color: _hasAccess ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUuidInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _uuidController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter User UUID to chat',
                  hintStyle: const TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              onPressed: _startChat,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHistory() {
    if (_threadsLoading && _threads.isEmpty && _groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty && _groups.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshThreads();
        await _loadDiscoverUsers();
        await _loadGroups();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        itemCount: _groups.length + _threads.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.08)),
        itemBuilder: (context, index) {
          if (index < _groups.length) {
            final g = _groups[index];
            return _buildGroupTile(g);
          } else {
            final t = _threads[index - _groups.length];
            return _buildThreadTile(t);
          }
        },
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    final groupName = (group['group_name'] ?? 'Group').toString();
    final lastMessage = (group['last_message'] ?? '').toString();
    final memberCount = group['member_count'] ?? 0;
    final myRole = (group['my_role'] ?? '').toString();
    final isSuperAdmin = myRole == 'super_admin';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.teal,
        child: Text(
          groupName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.group_rounded, color: Colors.teal, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              groupName,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        lastMessage.isEmpty ? '$memberCount members' : lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: () => _openGroupChat(group),
      onLongPress: () => _showGroupOptionsDialog(group, isSuperAdmin),
    );
  }

  void _showGroupOptionsDialog(Map<String, dynamic> group, bool isSuperAdmin) {
    final groupName = (group['group_name'] ?? 'Group').toString();
    final groupId = (group['id'] ?? '').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(groupName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Colors.white70),
              title: Text('Group Info', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _openGroupChat(group);
              },
            ),
            if (isSuperAdmin)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: Text('Delete Group', style: GoogleFonts.poppins(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteGroup(groupId, groupName);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Group?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete "$groupName"? This cannot be undone. All messages and members will be removed.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabaseService.deleteGroup(groupId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "$groupName" deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadGroups();
                _refreshThreads();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete group: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadTile(Map<String, dynamic> t) {
    final username = (t['other_username'] ?? t['username'] ?? '').toString();
    final displayName = (t['other_display_name'] ?? '').toString();
    final lastMessage = (t['last_message'] ?? '').toString();
    final unread = int.tryParse((t['unread_count'] ?? 0).toString()) ?? 0;
    final otherId = (t['other_user_id'] ?? t['other_id'] ?? '').toString();
    final hasStatus = _usersWithActiveStatus.contains(otherId);

    // Build the avatar letter
    final letter = ((displayName.trim().isNotEmpty ? displayName : username).isNotEmpty)
        ? (displayName.trim().isNotEmpty ? displayName : username)[0]
        : '?';

    // Build avatar with optional green status ring (WhatsApp-style)
    Widget leadingAvatar;
    if (hasStatus) {
      leadingAvatar = GestureDetector(
        onTap: () => _tabController.animateTo(1),
        child: CircleAvatar(
          radius: 29,
          backgroundColor: const Color(0xFF25D366),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF0B141A),
            child: CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
    } else {
      leadingAvatar = CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF6366F1),
        child: Text(letter, style: const TextStyle(color: Colors.white)),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leadingAvatar,
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName.trim().isNotEmpty ? displayName : username,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: unread > 0 ? Colors.white : Colors.white60,
          fontSize: 12,
          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.6)),
              ),
              child: Text(
                unread.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: () {
        final otherUser = {
          'id': t['other_user_id'] ?? t['other_id'],
          'username': t['other_username'] ?? t['username'],
          'display_name': t['other_display_name'],
          'email': t['other_email'] ?? t['email'],
        };
        _openChatWith(otherUser);
      },
      // Long press to delete chat (WhatsApp-like)
      onLongPress: () => _showDeleteChatDialog(t),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white.withOpacity(0.1), size: 100),
          const SizedBox(height: 20),
          Text(
            'No chat history yet\nStart a chat by UUID or Discover',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
