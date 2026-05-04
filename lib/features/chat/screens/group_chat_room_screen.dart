import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../services/supabase_service.dart';
import '../../../local_db/local_chat_store.dart';
import '../../../shared/widgets/rich_text_editor.dart';

class GroupChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic> currentUser;

  const GroupChatRoomScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupChatRoomScreen> createState() => _GroupChatRoomScreenState();
}

class _GroupChatRoomScreenState extends State<GroupChatRoomScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _scrollController = ScrollController();

  final _imagePicker = ImagePicker();
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  final Map<int, String> _signedUrlCache = {};
  final Map<int, String> _localMediaCache = {};
  int? _currentlyPlayingMessageId;
  bool _isRecording = false;

  Map<String, dynamic>? _replyToMessage;
  List<Map<String, dynamic>> _members = [];
  Map<String, String> _memberNames = {}; // userId -> displayName
  Map<String, String> _memberRoles = {}; // userId -> role

  // Rich text
  bool _showRichTextToolbar = false;

  // Editing
  Map<String, dynamic>? _editingMessage;

  // Admin state
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _onlyAdminsCanSend = false;
  bool _onlyAdminsCanEditInfo = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadGroupSettings();

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _currentlyPlayingMessageId = null);
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _supabaseService.getGroupMembers(widget.group['group_id'] ?? widget.group['id']);
      if (mounted) {
        setState(() {
          _members = members;
          _memberNames = {};
          _memberRoles = {};
          for (final m in members) {
            final profile = m['profiles'] as Map<String, dynamic>?;
            if (profile != null) {
              final userId = (profile['id'] ?? m['user_id']).toString();
              _memberNames[userId] = (profile['display_name'] ?? profile['username'] ?? 'User').toString();
              _memberRoles[userId] = (m['role'] ?? 'member').toString();
            }
          }
          // Determine admin status
          final myId = widget.currentUser['id'].toString();
          _isSuperAdmin = _memberRoles[myId] == 'super_admin';
          _isAdmin = _isSuperAdmin || _memberRoles[myId] == 'admin';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGroupSettings() async {
    try {
      final groupId = widget.group['group_id'] ?? widget.group['id'];
      final res = await Supabase.instance.client
          .from('groups')
          .select('only_admins_can_send,only_admins_can_edit_info')
          .eq('id', groupId)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _onlyAdminsCanSend = res['only_admins_can_send'] == true;
          _onlyAdminsCanEditInfo = res['only_admins_can_edit_info'] == true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  bool get _canSendMessage {
    if (_onlyAdminsCanSend && !_isAdmin) return false;
    return true;
  }

  Future<void> _sendMessage() async {
    if (!_canSendMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can send messages in this group')),
      );
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Check if editing
    if (_editingMessage != null) {
      final createdAt = DateTime.tryParse((_editingMessage!['created_at'] ?? '').toString());
      if (createdAt != null && DateTime.now().difference(createdAt).inMinutes <= 20) {
        await _supabaseService.editGroupMessage(
          messageId: _editingMessage!['id'],
          newContent: content,
        );
        setState(() => _editingMessage = null);
        _messageController.clear();
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit window (20 min) has expired')),
        );
        setState(() => _editingMessage = null);
        return;
      }
    }

    _messageController.clear();

    // Check for rich text formatting
    final hasFormatting = RichTextEditor.hasFormatting(content);
    String messageType = 'text';
    if (_isOnlyEmoji(content)) messageType = 'emoji';

    await _supabaseService.sendGroupMessage(
      groupId: widget.group['group_id'] ?? widget.group['id'],
      senderId: widget.currentUser['id'],
      content: content,
      messageType: messageType,
      replyToId: _replyToMessage?['id'],
      isRichText: hasFormatting,
      richTextJson: hasFormatting ? RichTextEditor.toJsonString(RichTextEditor.parseMarkdownToSegments(content)) : null,
    );

    setState(() => _replyToMessage = null);
    _scrollToBottom();
  }

  bool _isOnlyEmoji(String text) {
    final emojiRegex = RegExp(
      r'^[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{200D}\u{20E3}\u{FE0F}\u{E0020}-\u{E007F}\s]+$',
      unicode: true,
    );
    return emojiRegex.hasMatch(text) && text.replaceAll(RegExp(r'\s'), '').isNotEmpty;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    // Offer crop
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF6366F1),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF0B141A),
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.original,
          ],
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );

    if (croppedFile == null) return; // User cancelled crop

    final file = File(croppedFile.path);
    final bytes = await file.readAsBytes();
    final ext = p.extension(croppedFile.path).replaceFirst('.', '').toLowerCase();
    final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';

    final mediaPath = await _supabaseService.uploadChatMedia(
      ownerUserId: widget.currentUser['id'],
      bytes: bytes,
      ext: ext.isEmpty ? 'jpg' : ext,
      mime: mime,
    );

    await _supabaseService.sendGroupMessage(
      groupId: widget.group['group_id'] ?? widget.group['id'],
      senderId: widget.currentUser['id'],
      content: '',
      messageType: 'image',
      mediaPath: mediaPath,
      mediaMime: mime,
      mediaSizeBytes: bytes.length,
      replyToId: _replyToMessage?['id'],
    );

    setState(() => _replyToMessage = null);
    _scrollToBottom();
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.first;
    if (platformFile.bytes == null && platformFile.path == null) return;

    List<int> bytes;
    if (platformFile.bytes != null) {
      bytes = platformFile.bytes!;
    } else {
      bytes = await File(platformFile.path!).readAsBytes();
    }

    final fileName = platformFile.name;
    final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    const mime = 'application/octet-stream';

    final mediaPath = await _supabaseService.uploadFile(
      ownerUserId: widget.currentUser['id'],
      bytes: bytes,
      fileName: fileName,
      mime: mime,
    );

    await _supabaseService.sendGroupMessage(
      groupId: widget.group['group_id'] ?? widget.group['id'],
      senderId: widget.currentUser['id'],
      content: '',
      messageType: 'file',
      mediaPath: mediaPath,
      mediaMime: mime,
      mediaName: fileName,
      mediaSizeBytes: bytes.length,
    );

    setState(() => _replyToMessage = null);
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (!_canSendMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can send messages in this group')),
      );
      return;
    }

    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;

      final file = File(path);
      final bytes = await file.readAsBytes();
      final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
      final durationMs = await _probeAudioDurationMs(file);
      const mime = 'audio/mp4';

      final mediaPath = await _supabaseService.uploadChatMedia(
        ownerUserId: widget.currentUser['id'],
        bytes: bytes,
        ext: ext.isEmpty ? 'm4a' : ext,
        mime: mime,
      );

      await _supabaseService.sendGroupMessage(
        groupId: widget.group['group_id'] ?? widget.group['id'],
        senderId: widget.currentUser['id'],
        content: '',
        messageType: 'audio',
        mediaPath: mediaPath,
        mediaMime: mime,
        mediaDurationMs: durationMs,
        mediaSizeBytes: bytes.length,
      );

      _scrollToBottom();
      return;
    }

    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath = p.join(dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: filePath,
    );

    setState(() => _isRecording = true);
  }

  Future<int?> _probeAudioDurationMs(File file) async {
    try {
      final tmp = AudioPlayer();
      await tmp.setFilePath(file.path);
      final d = tmp.duration;
      await tmp.dispose();
      return d?.inMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<void> _playOrPauseAudio(Map<String, dynamic> message) async {
    final int id = message['id'] as int;
    if (_currentlyPlayingMessageId == id && _audioPlayer.playing) {
      await _audioPlayer.pause();
      setState(() {});
      return;
    }

    final mediaPath = message['media_path'] as String?;
    if (mediaPath == null) return;

    try {
      final localPath = await _supabaseService.cacheMediaLocally(
        mediaPath: mediaPath,
        mediaMime: message['media_mime'] ?? '',
      );
      await _audioPlayer.stop();
      if (localPath.startsWith('/') || localPath.startsWith('file://')) {
        await _audioPlayer.setFilePath(localPath.startsWith('file://') ? localPath.substring(7) : localPath);
      } else {
        await _audioPlayer.setUrl(localPath);
      }
      _currentlyPlayingMessageId = id;
      await _audioPlayer.play();
      setState(() {});
    } catch (_) {}
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setModalState) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        (widget.group['group_name'] ?? 'G')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      widget.group['group_name'] ?? 'Group',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.group['group_description'] != null && (widget.group['group_description'] as String).isNotEmpty)
                    Center(
                      child: Text(
                        widget.group['group_description'],
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Admin settings section
                  if (_isAdmin) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Settings', style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: _onlyAdminsCanSend,
                            onChanged: (val) async {
                              await _supabaseService.updateGroupSettings(
                                groupId: widget.group['group_id'] ?? widget.group['id'],
                                onlyAdminsCanSend: val,
                              );
                              setModalState(() => _onlyAdminsCanSend = val);
                              setState(() => _onlyAdminsCanSend = val);
                            },
                            title: Text('Only admins can send messages', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                            activeColor: const Color(0xFF6366F1),
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            value: _onlyAdminsCanEditInfo,
                            onChanged: (val) async {
                              await _supabaseService.updateGroupSettings(
                                groupId: widget.group['group_id'] ?? widget.group['id'],
                                onlyAdminsCanEditInfo: val,
                              );
                              setModalState(() => _onlyAdminsCanEditInfo = val);
                              setState(() => _onlyAdminsCanEditInfo = val);
                            },
                            title: Text('Only admins can edit group info', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                            activeColor: const Color(0xFF6366F1),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Text('Members (${_members.length})', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._members.map((m) {
                    final profile = m['profiles'] as Map<String, dynamic>?;
                    final name = profile?['display_name'] ?? profile?['username'] ?? 'User';
                    final userId = (profile?['id'] ?? m['user_id']).toString();
                    final role = (m['role'] ?? 'member').toString();
                    final isMe = userId == widget.currentUser['id'];
                    final memberIsAdmin = role == 'admin' || role == 'super_admin';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(name.toString()[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(
                        isMe ? '$name (You)' : name.toString(),
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      subtitle: role != 'member'
                          ? Text(
                              role == 'super_admin' ? 'Super Admin' : 'Admin',
                              style: GoogleFonts.poppins(color: role == 'super_admin' ? Colors.amber : Colors.orangeAccent, fontSize: 11),
                            )
                          : null,
                      trailing: _isAdmin && !isMe && role != 'super_admin'
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                              color: const Color(0xFF203A43),
                              onSelected: (val) async {
                                final groupId = widget.group['group_id'] ?? widget.group['id'];
                                if (val == 'promote' && _isSuperAdmin) {
                                  await _supabaseService.promoteGroupAdmin(groupId: groupId, userId: userId);
                                  _loadMembers();
                                  Navigator.pop(context); // Close sheet to refresh
                                } else if (val == 'demote' && _isSuperAdmin) {
                                  await _supabaseService.demoteGroupAdmin(groupId: groupId, userId: userId);
                                  _loadMembers();
                                  Navigator.pop(context);
                                } else if (val == 'remove') {
                                  await _supabaseService.removeGroupMember(groupId: groupId, userId: userId);
                                  _loadMembers();
                                  Navigator.pop(context);
                                }
                              },
                              itemBuilder: (_) => [
                                if (_isSuperAdmin && role == 'member')
                                  const PopupMenuItem(value: 'promote', child: Text('Promote to Admin', style: TextStyle(color: Colors.white))),
                                if (_isSuperAdmin && role == 'admin')
                                  const PopupMenuItem(value: 'demote', child: Text('Demote to Member', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 'remove', child: Text('Remove from Group', style: TextStyle(color: Colors.redAccent))),
                              ],
                            )
                          : null,
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF203A43),
                            title: Text('Leave Group?', style: GoogleFonts.poppins(color: Colors.white)),
                            content: Text('You will no longer receive messages from this group.',
                                style: GoogleFonts.poppins(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _supabaseService.leaveGroup(widget.group['group_id'] ?? widget.group['id']);
                          if (mounted) Navigator.pop(context); // Close bottom sheet
                          if (mounted) Navigator.pop(context); // Close chat room
                        }
                      },
                      icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                      label: Text('Leave Group', style: GoogleFonts.poppins(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                    ),
                  ),

                  // [FIX #5] Delete Group button for super_admin only
                  if (_isSuperAdmin) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF203A43),
                              title: Text('Delete Group?', style: GoogleFonts.poppins(color: Colors.redAccent)),
                              content: Text('This will permanently delete this group and all its messages. This cannot be undone.',
                                  style: GoogleFonts.poppins(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  child: const Text('Delete Permanently'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final groupId = widget.group['group_id'] ?? widget.group['id'];
                            await _supabaseService.deleteGroup(groupId.toString());
                            if (mounted) Navigator.pop(context); // Close bottom sheet
                            if (mounted) Navigator.pop(context); // Close chat room
                          }
                        },
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                        label: Text('Delete Group', style: GoogleFonts.poppins(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group['group_id'] ?? widget.group['id'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: _showGroupInfo,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  (widget.group['group_name'] ?? 'G')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group['group_name'] ?? 'Group',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _onlyAdminsCanSend ? 'Only admins can send' : '${widget.group['member_count'] ?? _members.length} members',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: const Color(0xFF203A43),
            onSelected: (val) {
              if (val == 'group_info') _showGroupInfo();
              if (val == 'rich_text') {
                setState(() => _showRichTextToolbar = !_showRichTextToolbar);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rich_text',
                child: Row(
                  children: [
                    Icon(Icons.format_size_rounded,
                        color: _showRichTextToolbar ? const Color(0xFF6366F1) : Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Text(_showRichTextToolbar ? 'Hide Formatting' : 'Text Formatting',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'group_info', child: Text('Group Info', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned messages header
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabaseService.getGroupMessages(groupId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final pinned = snapshot.data!.where((m) => m['is_pinned'] == true).toList();
              if (pinned.isEmpty) return const SizedBox.shrink();
              return _buildPinnedMessagesHeader(pinned);
            },
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getGroupMessages(groupId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == widget.currentUser['id'];
                    return _buildGroupMessageBubble(message, isMe, messages);
                  },
                );
              },
            ),
          ),
          if (_replyToMessage != null) _buildReplyPreview(),
          if (_editingMessage != null) _buildEditPreview(),
          if (_showRichTextToolbar) _buildRichTextToolbar(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildPinnedMessagesHeader(List<Map<String, dynamic>> pinned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF6366F1).withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: Color(0xFF6366F1), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${pinned.length} pinned message${pinned.length > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () => _showPinnedMessagesDialog(pinned),
            child: Text('View', style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showPinnedMessagesDialog(List<Map<String, dynamic>> pinned) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
          Padding(padding: const EdgeInsets.all(16), child: Text('Pinned Messages', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pinned.length,
              itemBuilder: (ctx, i) {
                final msg = pinned[i];
                final senderName = _memberNames[msg['sender_id']] ?? 'User';
                return ListTile(
                  leading: const Icon(Icons.push_pin, color: Color(0xFF6366F1), size: 18),
                  title: Text(senderName, style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w600)),
                  subtitle: Text((msg['content'] ?? '').toString().isEmpty ? '[Media]' : (msg['content'] ?? '').toString(),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            width: 3, height: 36,
            decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyToMessage!['sender_id'] == widget.currentUser['id'] ? 'You' : (_memberNames[_replyToMessage!['sender_id']] ?? 'User'),
                  style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  (_replyToMessage!['content'] ?? '').toString().isEmpty ? '[Media]' : (_replyToMessage!['content'] ?? '').toString(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
            onPressed: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    final createdAt = DateTime.tryParse((_editingMessage!['created_at'] ?? '').toString());
    final remaining = createdAt != null ? 20 - DateTime.now().difference(createdAt).inMinutes : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Editing message', style: GoogleFonts.poppins(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                if (remaining > 0)
                  Text('$remaining min remaining', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
            onPressed: () {
              setState(() {
                _editingMessage = null;
                _messageController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withOpacity(0.03),
      child: Row(
        children: [
          const Text('Format: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 4),
          _formatBtn('B', FontWeight.bold, 'bold'),
          _formatBtn('I', FontStyle.italic, 'italic'),
          _formatBtn('S~', TextDecoration.lineThrough, 'strikethrough'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 16),
            onPressed: () => setState(() => _showRichTextToolbar = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _formatBtn(String label, dynamic style, String format) {
    return GestureDetector(
      onTap: () {
        RichTextEditor.applyFormat(_messageController, format);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(
          color: Colors.white, fontSize: 12,
          fontWeight: style is FontWeight ? style : FontWeight.normal,
          fontStyle: style is FontStyle ? style : FontStyle.normal,
          decoration: style is TextDecoration ? style : TextDecoration.none,
        )),
      ),
    );
  }

  Widget _buildGroupMessageBubble(Map<String, dynamic> message, bool isMe, List<Map<String, dynamic>> allMessages) {
    final type = (message['message_type'] ?? 'text').toString();
    final isDeleted = type == 'deleted';
    // [UPDATE #6] Check if this message was deleted for the current user
    final deletedForUsers = message['deleted_for_users'];
    final isDeletedForMe = deletedForUsers != null &&
        (deletedForUsers is List && deletedForUsers.contains(widget.currentUser['id']));
    if (isDeletedForMe && !isDeleted) return const SizedBox.shrink();
    final isEmoji = type == 'emoji';
    final senderName = _memberNames[message['sender_id']] ?? 'User';
    final senderRole = _memberRoles[message['sender_id']] ?? 'member';
    final isEmojiOnly = isEmoji || (type == 'text' && _isOnlyEmoji((message['content'] ?? '').toString()));
    final isPinned = message['is_pinned'] == true;
    final isForwarded = message['is_forwarded'] == true;
    final isStarred = message['is_starred'] == true;
    final isRichText = message['is_rich_text'] == true;
    final editedAt = message['edited_at'];
    final richTextJson = message['rich_text_json'] as String?;

    // Reply
    final replyToId = message['reply_to_id'];
    Map<String, dynamic>? replyToMsg;
    if (replyToId != null) {
      try { replyToMsg = allMessages.firstWhere((m) => m['id'] == replyToId); } catch (_) {}
    }

    // Media expiry
    final mediaExpiresAt = message['media_expires_at'];
    final isMediaExpired = mediaExpiresAt != null && DateTime.tryParse(mediaExpiresAt.toString())?.isBefore(DateTime.now()) == true;

    return Dismissible(
      key: ValueKey(message['id']),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          setState(() => _replyToMessage = message);
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply_rounded, color: Colors.white38, size: 28),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _showGroupMessageOptions(message, isMe),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            constraints: BoxConstraints(
              maxWidth: isEmojiOnly ? MediaQuery.of(context).size.width * 0.9 : MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (for group chats)
                if (!isMe && !isDeleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          senderName,
                          style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        if (senderRole != 'member') ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            color: senderRole == 'super_admin' ? Colors.amber : Colors.orangeAccent,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  padding: isEmojiOnly
                      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: isEmojiOnly
                      ? null
                      : BoxDecoration(
                          color: isMe ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                          ),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Forwarded label
                      if (isForwarded && !isDeleted)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shortcut_rounded, color: Colors.white38, size: 12),
                              const SizedBox(width: 4),
                              Text('Forwarded', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      // Pinned indicator
                      if (isPinned && !isDeleted)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.push_pin, color: Colors.amber, size: 12),
                              const SizedBox(width: 4),
                              Text('Pinned', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 10)),
                            ],
                          ),
                        ),
                      if (replyToMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(color: const Color(0xFF6366F1), width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyToMsg['sender_id'] == widget.currentUser['id'] ? 'You' : (_memberNames[replyToMsg['sender_id']] ?? 'User'),
                                style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                (replyToMsg['content'] ?? '').toString().isEmpty ? '[Media]' : (replyToMsg['content'] ?? '').toString(),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (isDeleted)
                        Text('This message was deleted', style: TextStyle(color: Colors.white38, fontSize: 14, fontStyle: FontStyle.italic))
                      else if (isEmojiOnly)
                        Text((message['content'] ?? '').toString(), style: const TextStyle(fontSize: 48), textAlign: TextAlign.center)
                      else if (type == 'text') ...[
                        if (isRichText && richTextJson != null && richTextJson.isNotEmpty)
                          _buildRichTextContent(richTextJson, isMe ? Colors.white : Colors.white)
                        else if (RichTextEditor.hasFormatting((message['content'] ?? '').toString()))
                          _buildRichTextContentFromMarkdown((message['content'] ?? '').toString(), isMe ? Colors.white : Colors.white)
                        else
                          Text((message['content'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 15)),
                      ]
                      else if (type == 'image')
                        isMediaExpired ? _buildExpiredMedia() : _buildGroupImageMessage(message)
                      else if (type == 'audio')
                        _buildGroupAudioMessage(message)
                      else if (type == 'file')
                        isMediaExpired ? _buildExpiredFile() : _buildGroupFileMessage(message)
                      else
                        Text((message['content'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 15)),
                      if (!isDeleted && !isEmojiOnly) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isStarred)
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                            if (editedAt != null) ...[
                              const Icon(Icons.edit_rounded, color: Colors.white38, size: 10),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              _formatTime(DateTime.tryParse((message['created_at'] ?? '').toString()) ?? DateTime.now()),
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichTextContent(String richTextJson, Color color) {
    final segments = RichTextEditor.parseRichText(richTextJson);
    if (segments.isEmpty) return const SizedBox.shrink();
    return RichText(
      text: TextSpan(
        children: RichTextEditor.buildTextSpans(segments, color: color, fontSize: 15),
      ),
    );
  }

  Widget _buildRichTextContentFromMarkdown(String text, Color color) {
    final segments = RichTextEditor.parseMarkdownToSegments(text);
    return RichText(
      text: TextSpan(
        children: RichTextEditor.buildTextSpans(segments, color: color, fontSize: 15),
      ),
    );
  }

  Widget _buildExpiredMedia() => Container(
    width: 220, height: 120,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
    child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.timer_off_rounded, color: Colors.white38, size: 32),
      SizedBox(height: 8),
      Text('Media expired', style: TextStyle(color: Colors.white38, fontSize: 12)),
    ])),
  );

  Widget _buildExpiredFile() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.timer_off_rounded, color: Colors.white38, size: 36),
      SizedBox(width: 10),
      Text('File expired', style: TextStyle(color: Colors.white38, fontSize: 14)),
    ]),
  );

  Widget _buildGroupImageMessage(Map<String, dynamic> message) {
    final mediaPath = message['media_path'] as String?;
    if (mediaPath == null) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _supabaseService.cacheMediaLocally(mediaPath: mediaPath, mediaMime: message['media_mime'] ?? ''),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return const SizedBox(width: 180, height: 180, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        if (url.startsWith('/') || url.startsWith('file://')) {
          final filePath = url.startsWith('file://') ? url.substring(7) : url;
          return ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(filePath), width: 220, height: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 220, height: 220, color: Colors.white.withOpacity(0.08), child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white54)))));
        }
        return ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: url, width: 220, height: 220, fit: BoxFit.cover, placeholder: (_, __) => Container(width: 220, height: 220, color: Colors.white.withOpacity(0.08), child: const Center(child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (_, __, ___) => Container(width: 220, height: 220, color: Colors.white.withOpacity(0.08), child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white54)))));
      },
    );
  }

  Widget _buildGroupAudioMessage(Map<String, dynamic> message) {
    final id = message['id'] as int;
    final isPlaying = _currentlyPlayingMessageId == id && _audioPlayer.playing;
    final durationMs = message['media_duration_ms'] as int?;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _playOrPauseAudio(message),
        icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 34)),
      const SizedBox(width: 8),
      Text(durationMs == null ? 'Voice note' : _formatDurationMs(durationMs), style: const TextStyle(color: Colors.white, fontSize: 14)),
    ]);
  }

  Widget _buildGroupFileMessage(Map<String, dynamic> message) {
    final fileName = (message['media_name'] ?? 'File').toString();
    final fileSize = message['media_size_bytes'] as int?;
    final mime = (message['media_mime'] ?? '').toString();
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

    // Different icons and colors for different file types
    IconData fileIcon = Icons.insert_drive_file_rounded;
    Color iconColor = const Color(0xFF6366F1);
    Color bgColor = const Color(0xFF6366F1).withOpacity(0.15);

    if (mime.contains('pdf') || ext == 'pdf') {
      fileIcon = Icons.picture_as_pdf_rounded; iconColor = Colors.redAccent; bgColor = Colors.redAccent.withOpacity(0.15);
    } else if (mime.contains('zip') || mime.contains('rar') || mime.contains('7z') || ['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      fileIcon = Icons.folder_zip_rounded; iconColor = Colors.orangeAccent; bgColor = Colors.orangeAccent.withOpacity(0.15);
    } else if (mime.contains('android') || mime.contains('apk') || ext == 'apk') {
      fileIcon = Icons.android_rounded; iconColor = Colors.greenAccent; bgColor = Colors.greenAccent.withOpacity(0.15);
    } else if (mime.contains('word') || mime.contains('doc') || ['doc', 'docx'].contains(ext)) {
      fileIcon = Icons.description_rounded; iconColor = const Color(0xFF2B7CD3); bgColor = const Color(0xFF2B7CD3).withOpacity(0.15);
    } else if (mime.contains('sheet') || mime.contains('xls') || ['xls', 'xlsx', 'csv'].contains(ext)) {
      fileIcon = Icons.table_chart_rounded; iconColor = Colors.green; bgColor = Colors.green.withOpacity(0.15);
    } else if (mime.contains('presentation') || mime.contains('ppt') || ['ppt', 'pptx'].contains(ext)) {
      fileIcon = Icons.slideshow_rounded; iconColor = Colors.deepOrange; bgColor = Colors.deepOrange.withOpacity(0.15);
    } else if (mime.contains('text') || ['txt', 'md', 'log'].contains(ext)) {
      fileIcon = Icons.article_rounded; iconColor = Colors.grey; bgColor = Colors.grey.withOpacity(0.15);
    }

    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: iconColor.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(fileIcon, color: iconColor, size: 32)),
        const SizedBox(width: 12),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: Text(ext.toUpperCase(), style: GoogleFonts.poppins(color: iconColor, fontSize: 9, fontWeight: FontWeight.w700))),
            if (fileSize != null) ...[const SizedBox(width: 6), Text(_formatBytes(fileSize), style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11))],
          ]),
        ])),
      ]),
    );
  }

  void _showGroupMessageOptions(Map<String, dynamic> message, bool isMe) {
    final isDeleted = (message['message_type'] ?? '') == 'deleted';
    final isPinned = message['is_pinned'] == true;
    final isStarred = message['is_starred'] == true;
    final createdAt = DateTime.tryParse((message['created_at'] ?? '').toString());
    final canEdit = isMe && createdAt != null && DateTime.now().difference(createdAt).inMinutes <= 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 12),
          if (!isDeleted) ...[
            ListTile(leading: const Icon(Icons.reply_rounded, color: Colors.white70), title: Text('Reply', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); setState(() => _replyToMessage = message); }),
            ListTile(leading: const Icon(Icons.copy_rounded, color: Colors.white70), title: Text('Copy', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Clipboard.setData(ClipboardData(text: (message['content'] ?? '').toString())); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'))); }),
            // Forward
            ListTile(leading: const Icon(Icons.shortcut_rounded, color: Colors.white70), title: Text('Forward', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _showForwardDialog(message); }),
            // Star
            ListTile(
              leading: Icon(isStarred ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber),
              title: Text(isStarred ? 'Unstar' : 'Star', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _supabaseService.starGroupMessage(messageId: message['id'], starred: !isStarred);
              },
            ),
            // Pin (admin only)
            if (_isAdmin)
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.amber),
                title: Text(isPinned ? 'Unpin' : 'Pin', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _supabaseService.pinGroupMessage(messageId: message['id'], pinned: !isPinned);
                },
              ),
            // Edit (within 20 min)
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.orangeAccent),
                title: Text('Edit', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _editingMessage = message;
                    _messageController.text = (message['content'] ?? '').toString();
                  });
                },
              ),
          ],
          if (isMe && !isDeleted)
            ListTile(leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent), title: Text('Delete for everyone', style: GoogleFonts.poppins(color: Colors.redAccent)),
              onTap: () async { Navigator.pop(ctx); await _supabaseService.deleteGroupMessageForEveryone(messageId: message['id']); }),
          // [UPDATE #6] Delete for me option in group chat
          if (!isDeleted)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.orangeAccent),
              title: Text('Delete for me', style: GoogleFonts.poppins(color: Colors.orangeAccent)),
              onTap: () async {
                Navigator.pop(ctx);
                await _supabaseService.deleteGroupMessageForMe(
                  messageId: message['id'],
                  userId: widget.currentUser['id'],
                );
              },
            ),
          // Share
          if (!isDeleted && (message['content'] ?? '').toString().isNotEmpty)
            ListTile(leading: const Icon(Icons.share_rounded, color: Colors.white70), title: Text('Share', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); Share.share((message['content'] ?? '').toString()); }),
        ]),
          ),
        ),
    );
  }

  void _showForwardDialog(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabaseService.listProfiles(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
              Padding(padding: const EdgeInsets.all(16), child: Text('Forward to...', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final user = users[i];
                    if (user['id'] == widget.currentUser['id']) return const SizedBox.shrink();
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: const Color(0xFF6366F1), child: Text((user['display_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                      title: Text(user['display_name'] ?? user['username'] ?? 'User', style: GoogleFonts.poppins(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _supabaseService.sendMessage(
                          senderId: widget.currentUser['id'],
                          receiverId: user['id'],
                          content: (message['content'] ?? '').toString(),
                          messageType: (message['message_type'] ?? 'text').toString(),
                          isForwarded: true,
                          forwardedFromId: message['sender_id'],
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Forwarded to ${user['display_name'] ?? 'User'}')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatBytes(int bytes) { if (bytes < 1024) return '$bytes B'; final kb = bytes / 1024; if (kb < 1024) return '${kb.toStringAsFixed(1)} KB'; return '${(kb / 1024).toStringAsFixed(1)} MB'; }
  String _formatDurationMs(int ms) { final s = (ms / 1000).round(); final m = s ~/ 60; final r = s % 60; return m > 0 ? '${m}m ${r}s' : '${r}s'; }
  String _formatTime(DateTime dt) { return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'; }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: SafeArea(child: Row(children: [
        IconButton(icon: const Icon(Icons.attach_file_rounded, color: Colors.white70), onPressed: _canSendMessage ? _pickAndSendFile : null),
        IconButton(icon: const Icon(Icons.image_rounded, color: Colors.white70), onPressed: _canSendMessage ? _pickAndSendImage : null),
        IconButton(icon: Icon(_isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded, color: _isRecording ? Colors.redAccent : Colors.white70), onPressed: _canSendMessage ? _toggleRecording : null),
        Expanded(child: Container(
          constraints: const BoxConstraints(maxHeight: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)),
          child: TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white),
            maxLines: null,
            scrollController: ScrollController(),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            enabled: _canSendMessage,
            decoration: InputDecoration(
              hintText: _canSendMessage ? 'Message...' : 'Only admins can send',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        )),
        const SizedBox(width: 4),
        CircleAvatar(radius: 22, backgroundColor: const Color(0xFF6366F1),
          child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18), onPressed: _canSendMessage ? _sendMessage : null)),
      ])),
    );
  }
}
