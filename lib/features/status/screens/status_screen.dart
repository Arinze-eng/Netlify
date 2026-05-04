import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../services/notification_service.dart';

class StatusScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const StatusScreen({super.key, required this.currentUser});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with TickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;

  // My status
  List<Map<String, dynamic>> _myStatus = [];

  // Other users' status grouped by user
  Map<String, List<Map<String, dynamic>>> _otherStatus = {};
  Map<String, String> _userNames = {};
  Map<String, String> _userDisplayNames = {};

  // Track which users have active status (for green ring indicator)
  Set<String> _usersWithActiveStatus = {};

  // [FIX #3] Status notification tracking
  Set<String> _notifiedStatusIds = {};
  Stream<List<Map<String, dynamic>>>? _statusStream;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _startStatusNotificationListener(); // [FIX #3]
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// [FIX #3] Listen for new status posts and show notifications immediately
  void _startStatusNotificationListener() {
    try {
      final myId = widget.currentUser['id'] as String;
      _statusStream = _supabaseService.getActiveStatusStream(currentUserId: myId);
      _statusStream?.listen((statuses) {
        if (!mounted) return;
        for (final s in statuses) {
          final statusId = (s['id'] ?? '').toString();
          final userId = (s['user_id'] ?? '').toString();
          // Only notify for OTHER users' statuses that we haven't notified about yet
          if (userId != myId && !_notifiedStatusIds.contains(statusId)) {
            _notifiedStatusIds.add(statusId);
            final name = _userDisplayNames[userId]?.isNotEmpty == true
                ? _userDisplayNames[userId]!
                : _userNames[userId] ?? 'Someone';
            NotificationService.showNewStatusNotification(
              title: '$name posted a status',
              body: 'Tap to view',
              payload: userId,
            );
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadStatus() async {
    try {
      setState(() => _isLoading = true);

      final myId = widget.currentUser['id'] as String;

      // Load all active status (not expired), filtering by privacy exclusions
      final allStatus = await _supabaseService.getActiveStatus(currentUserId: myId);

      // Separate my status and others'
      final myStatusList = <Map<String, dynamic>>[];
      final otherStatusMap = <String, List<Map<String, dynamic>>>{};
      final activeUsers = <String>{};

      for (final s in allStatus) {
        final userId = (s['user_id'] ?? '').toString();
        if (userId == myId) {
          myStatusList.add(s);
        } else {
          otherStatusMap.putIfAbsent(userId, () => []).add(s);
          activeUsers.add(userId);
        }
      }

      // Load profiles for names
      final profiles = await _supabaseService.listProfiles();
      final names = <String, String>{};
      final displayNames = <String, String>{};
      for (final p in profiles) {
        final id = (p['id'] ?? '').toString();
        names[id] = (p['username'] ?? 'User').toString();
        displayNames[id] = (p['display_name'] ?? '').toString();
      }

      if (mounted) {
        setState(() {
          _myStatus = myStatusList;
          _otherStatus = otherStatusMap;
          _userNames = names;
          _userDisplayNames = displayNames;
          _usersWithActiveStatus = activeUsers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Check if a user has active status (for green ring indicator)
  bool userHasActiveStatus(String userId) {
    return _usersWithActiveStatus.contains(userId);
  }

  void _showCreateStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2AABEE)),
              title: Text('Photo Status', style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Share one or more images (disappears in 19 hours)', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              onTap: () { Navigator.pop(ctx); _pickMultipleImageStatus(); },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded, color: Color(0xFF6366F1)),
              title: Text('Text Status', style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Write text with custom background (disappears in 19 hours)', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              onTap: () { Navigator.pop(ctx); _showTextStatusEditor(); },
            ),
          ],
        ),
      ),
    );
  }

  /// Pick multiple images for status (WhatsApp-like multi-status upload)
  /// Fixed: No more crashes - uses safe file handling with fallbacks
  Future<void> _pickMultipleImageStatus() async {
    try {
      final picker = ImagePicker();
      final List<XFile> picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;

      int successCount = 0;
      int failCount = 0;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${picked.length} image(s)...'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }

      for (final xfile in picked) {
        try {
          // Check file size - 10MB max
          final file = File(xfile.path);
          if (!await file.exists()) {
            failCount++;
            continue;
          }
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            failCount++;
            continue;
          }

          // Read bytes directly - skip image cropper to prevent crashes on some Android devices
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            failCount++;
            continue;
          }

          final ext = p.extension(xfile.path).replaceFirst('.', '').toLowerCase();
          final safeExt = (ext.isEmpty || !['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) ? 'jpg' : ext;
          final mime = (safeExt == 'png') ? 'image/png' : 'image/jpeg';

          final mediaPath = await _supabaseService.uploadStatusMedia(
            userId: widget.currentUser['id'],
            bytes: bytes,
            ext: safeExt,
            mime: mime,
          );

          // [FIX #9] No caption for multi-image, but no crash either
          await _supabaseService.createStatus(
            userId: widget.currentUser['id'],
            statusType: 'image',
            mediaPath: mediaPath,
            mediaMime: mime,
          );

          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('Failed to upload status image: $e');
        }
      }

      if (mounted) {
        final msg = failCount > 0
            ? '$successCount status(es) posted, $failCount failed'
            : '$successCount status(es) posted!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
      _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  /// Pick single image for status (kept for backward compat, uses multi-pick)
  Future<void> _pickImageStatus() async {
    await _pickMultipleImageStatus();
  }

  void _showTextStatusEditor() {
    final textController = TextEditingController();
    String bgColor = '#6366F1';
    bool isBold = false;

    final colors = [
      '#6366F1', '#2AABEE', '#E91E63', '#FF5722', '#4CAF50',
      '#FF9800', '#9C27B0', '#00BCD4', '#795548', '#607D8B',
      '#F44336', '#3F51B5', '#009688', '#CDDC39', '#FFEB3B',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 16,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 16),
                    Text('Text Status', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    // Preview
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: _hexToColor(bgColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            textController.text.isEmpty ? 'Type something...' : textController.text,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Text input
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bold toggle
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => isBold = !isBold),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isBold ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isBold ? const Color(0xFF6366F1) : Colors.white24),
                            ),
                            child: Text('B', style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Bold', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Color picker
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((c) {
                        final isSelected = c == bgColor;
                        return GestureDetector(
                          onTap: () => setModalState(() => bgColor = c),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _hexToColor(c),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await _supabaseService.createStatus(
                              userId: widget.currentUser['id'],
                              statusType: 'text',
                              content: text,
                              backgroundColor: bgColor,
                              isBold: isBold,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Status posted!'), backgroundColor: Colors.green),
                              );
                            }
                            _loadStatus();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                        child: Text('Post Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _viewStatus(List<Map<String, dynamic>> statuses, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StatusViewer(
          statuses: statuses,
          userId: userId,
          userName: _userDisplayNames[userId]?.isNotEmpty == true
              ? _userDisplayNames[userId]!
              : _userNames[userId] ?? 'User',
          currentUserId: widget.currentUser['id'] as String,
          supabaseService: _supabaseService,
          onStatusDeleted: _loadStatus, // [FIX #1] Callback to refresh after delete
        ),
      ),
    ).then((_) => _loadStatus());
  }

  void _showStatusPrivacy() async {
    try {
      final excludedIds = await _supabaseService.getStatusExcludedUsers(widget.currentUser['id']);
      final profiles = await _supabaseService.listProfiles();
      final myId = widget.currentUser['id'] as String;
      final otherUsers = profiles.where((p) => p['id'] != myId).toList();
      final excludedSet = excludedIds.toSet();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0F2027),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999))),
                      const SizedBox(height: 14),
                      Text('Status Privacy', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Excluded contacts won\'t see your status', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: otherUsers.map((u) {
                            final id = (u['id'] ?? '').toString();
                            final name = (u['display_name'] ?? u['username'] ?? 'User').toString();
                            final isExcluded = excludedSet.contains(id);
                            return SwitchListTile(
                              value: isExcluded,
                              onChanged: (v) async {
                                if (v) {
                                  await _supabaseService.excludeFromStatus(
                                    userId: widget.currentUser['id'],
                                    excludedUserId: id,
                                  );
                                  setModalState(() => excludedSet.add(id));
                                } else {
                                  await _supabaseService.includeInStatus(
                                    userId: widget.currentUser['id'],
                                    excludedUserId: id,
                                  );
                                  setModalState(() => excludedSet.remove(id));
                                }
                              },
                              title: Text(name, style: GoogleFonts.poppins(color: Colors.white)),
                              subtitle: Text((u['username'] ?? '').toString(), style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                              activeColor: Colors.redAccent,
                            );
                          }).toList(),
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Status', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip_rounded),
            onPressed: _showStatusPrivacy,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // My status
                  _buildMyStatusCard(),
                  const SizedBox(height: 20),
                  // Recent updates
                  if (_otherStatus.isNotEmpty) ...[
                    Text('Recent updates', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ..._otherStatus.entries.map((entry) {
                      final userId = entry.key;
                      final statuses = entry.value;
                      final name = _userDisplayNames[userId]?.isNotEmpty == true
                          ? _userDisplayNames[userId]!
                          : _userNames[userId] ?? 'User';
                      final hasUnviewed = statuses.any((s) => s['viewed_by_me'] != true);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildStatusAvatar(
                          name: name,
                          hasUnviewed: hasUnviewed,
                          statusCount: statuses.length,
                        ),
                        title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _formatStatusTime(statuses.last['created_at']),
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                        ),
                        onTap: () => _viewStatus(statuses, userId),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.update_rounded, color: Colors.white.withOpacity(0.15), size: 64),
                          const SizedBox(height: 12),
                          Text('No status updates yet', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateStatusOptions,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  /// Build a WhatsApp-like status avatar with green ring indicator
  Widget _buildStatusAvatar({
    required String name,
    required bool hasUnviewed,
    required int statusCount,
  }) {
    return Stack(
      children: [
        // Outer ring - green for unviewed, grey for viewed (WhatsApp-style)
        CircleAvatar(
          radius: 28,
          backgroundColor: hasUnviewed ? const Color(0xFF25D366) : Colors.white24,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF0B141A),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        // Status count badge
        if (statusCount > 1)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
              child: Text('$statusCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  /// Build the green ring indicator for chat list / discover users
  /// [FIX #7] Now tappable - tapping the green ring takes you to that user's status
  static Widget buildStatusRingIndicator({
    required Widget child,
    required bool hasActiveStatus,
    double radius = 26,
    VoidCallback? onTap, // [FIX #7] callback when green ring is tapped
  }) {
    if (!hasActiveStatus) return child;
    final ringWidget = CircleAvatar(
      radius: radius + 3,
      backgroundColor: const Color(0xFF25D366),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF0B141A),
        child: child,
      ),
    );
    // [FIX #7] If onTap provided, wrap in GestureDetector
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: ringWidget,
      );
    }
    return ringWidget;
  }

  Widget _buildMyStatusCard() {
    return GestureDetector(
      onTap: _myStatus.isNotEmpty
          ? () => _viewStatus(_myStatus, widget.currentUser['id'] as String)
          : _showCreateStatusOptions,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                // [FIX #7] Green ring around my profile when I have status
                if (_myStatus.isNotEmpty)
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: const Color(0xFF25D366),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF0B141A),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          ((widget.currentUser['display_name'] ?? widget.currentUser['username'] ?? 'U') as String)[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      ((widget.currentUser['display_name'] ?? widget.currentUser['username'] ?? 'U') as String)[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (_myStatus.isNotEmpty)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.white, size: 12),
                    ),
                  ),
                if (_myStatus.isEmpty)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Status', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(
                    _myStatus.isEmpty ? 'Tap to add status update' : '${_myStatus.length} update${_myStatus.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatusTime(dynamic createdAt) {
    final dt = DateTime.tryParse((createdAt ?? '').toString());
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 19) return '${diff.inHours}h ago';
    return 'Expired';
  }
}

// Status viewer with swipe — [FIX #4] VERY SLOW with tap navigation
// User must tap to advance, auto-advance is very slow (30s per status)
class _StatusViewer extends StatefulWidget {
  final List<Map<String, dynamic>> statuses;
  final String userId;
  final String userName;
  final String currentUserId;
  final SupabaseService supabaseService;
  final VoidCallback? onStatusDeleted; // [FIX #1] Callback after deletion

  const _StatusViewer({
    required this.statuses,
    required this.userId,
    required this.userName,
    required this.currentUserId,
    required this.supabaseService,
    this.onStatusDeleted,
  });

  @override
  State<_StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<_StatusViewer> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _progressController;

  // Status like & reply state
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  // Pause state
  bool _isPaused = false;

  // [UPDATE #4] SUPER SLOW status viewing: 60 seconds per status
  // Auto-advance is extremely slow — user should tap to go to next status
  // if there are multiple statuses from the same user
  static const Duration _imageStatusDuration = Duration(seconds: 60);
  static const Duration _textStatusDuration = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: _getCurrentDuration(),
    );
    _startProgress();
    _markAsViewed();
    _loadLikeStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Duration _getCurrentDuration() {
    if (widget.statuses.isEmpty) return _textStatusDuration;
    final type = (widget.statuses[_currentIndex]['status_type'] ?? 'text').toString();
    return type == 'image' ? _imageStatusDuration : _textStatusDuration;
  }

  void _startProgress() {
    _progressController.duration = _getCurrentDuration();
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) _nextStatus();
    });
  }

  void _nextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _startProgress();
      _markAsViewed();
      _loadLikeStatus();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _startProgress();
      _markAsViewed();
      _loadLikeStatus();
    }
  }

  Future<void> _markAsViewed() async {
    try {
      final statusId = widget.statuses[_currentIndex]['id']?.toString();
      if (statusId != null && widget.userId != widget.currentUserId) {
        await widget.supabaseService.markStatusViewed(
          statusId: statusId,
          viewerId: widget.currentUserId,
        );
      }
    } catch (_) {}
  }

  Future<void> _loadLikeStatus() async {
    try {
      final statusId = widget.statuses[_currentIndex]['id']?.toString();
      if (statusId == null) return;

      final liked = await widget.supabaseService.isStatusLikedByMe(
        statusId: statusId,
        userId: widget.currentUserId,
      );
      final count = await widget.supabaseService.getStatusLikeCount(statusId);

      if (mounted) {
        setState(() {
          _isLiked = liked;
          _likeCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    setState(() => _isLikeLoading = true);

    try {
      final statusId = widget.statuses[_currentIndex]['id']?.toString();
      if (statusId == null) return;

      if (_isLiked) {
        await widget.supabaseService.unlikeStatus(
          statusId: statusId,
          userId: widget.currentUserId,
        );
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 999999);
        });
      } else {
        await widget.supabaseService.likeStatus(
          statusId: statusId,
          userId: widget.currentUserId,
        );
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLikeLoading = false);
    }
  }

  // [FIX #1] Delete current status
  Future<void> _deleteCurrentStatus() async {
    final statusId = widget.statuses[_currentIndex]['id']?.toString();
    if (statusId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Status?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This status will be permanently deleted.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.supabaseService.deleteStatus(statusId);

      if (!mounted) return;

      // Remove the deleted status from the list
      widget.statuses.removeAt(_currentIndex);

      if (widget.statuses.isEmpty) {
        // No more statuses, go back
        widget.onStatusDeleted?.call();
        Navigator.pop(context);
      } else {
        // Adjust index if needed
        if (_currentIndex >= widget.statuses.length) {
          _currentIndex = widget.statuses.length - 1;
        }
        setState(() {});
        _startProgress();
        _loadLikeStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showReplySheet() {
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: 14),
              Text('Reply to ${widget.userName}\'s status',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: replyController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type a reply...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = replyController.text.trim();
                    if (text.isEmpty) return;

                    final statusId = widget.statuses[_currentIndex]['id']?.toString();
                    if (statusId == null) return;

                    Navigator.pop(ctx);
                    try {
                      // [FIX #8] Status reply now actually sends a DM to the status author
                      await widget.supabaseService.replyToStatus(
                        statusId: statusId,
                        userId: widget.currentUserId,
                        content: text,
                        statusAuthorId: widget.userId, // Pass the status author's ID
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reply sent to ${widget.userName}'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to reply: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  child: Text('Send Reply', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusViewsSheet() async {
    try {
      final statusId = widget.statuses[_currentIndex]['id']?.toString();
      if (statusId == null) return;

      final views = await widget.supabaseService.getStatusViews(statusId);
      final likes = await widget.supabaseService.getStatusLikes(statusId);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0F2027),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white54, size: 18),
                      const SizedBox(width: 6),
                      Text('${views.length} view${views.length != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 20),
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 6),
                      Text('${likes.length} like${likes.length != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (views.isEmpty && likes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No views or likes yet', style: GoogleFonts.poppins(color: Colors.white54)),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Likers
                          if (likes.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Liked by', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            ...likes.map((like) {
                              final profile = like['profiles'] as Map<String, dynamic>?;
                              final name = profile != null
                                  ? ((profile['display_name'] ?? '').toString().trim().isNotEmpty
                                      ? profile['display_name']
                                      : profile['username'] ?? 'User')
                                  : 'User';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                                title: Text(name.toString(), style: GoogleFonts.poppins(color: Colors.white)),
                              );
                            }),
                            const Divider(color: Colors.white12),
                          ],
                          // Viewers
                          if (views.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Viewed by', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            ...views.map((view) {
                              final profile = view['profiles'] as Map<String, dynamic>?;
                              final name = profile != null
                                  ? ((profile['display_name'] ?? '').toString().trim().isNotEmpty
                                      ? profile['display_name']
                                      : profile['username'] ?? 'User')
                                  : 'User';
                              final viewedAt = DateTime.tryParse((view['viewed_at'] ?? '').toString());
                              final timeStr = viewedAt != null
                                  ? '${viewedAt.hour.toString().padLeft(2, '0')}:${viewedAt.minute.toString().padLeft(2, '0')}'
                                  : '';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.visibility, color: Colors.white38, size: 20),
                                title: Text(name.toString(), style: GoogleFonts.poppins(color: Colors.white)),
                                trailing: Text(timeStr, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: List.generate(widget.statuses.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _currentIndex
                            ? Colors.white
                            : i == _currentIndex
                                ? null
                                : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: i == _currentIndex
                          ? AnimatedBuilder(
                              animation: _progressController,
                              builder: (_, __) => FractionallySizedBox(
                                widthFactor: _progressController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(widget.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          _formatTime(widget.statuses[_currentIndex]['created_at']),
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // View count button (only for own status)
                  if (widget.userId == widget.currentUserId)
                    GestureDetector(
                      onTap: _showStatusViewsSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text('Views', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  // [FIX #1] Delete button for own status
                  if (widget.userId == widget.currentUserId)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: _deleteCurrentStatus,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Status content
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  final width = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < width / 3) {
                    // Previous
                    _prevStatus();
                  } else {
                    // Next
                    _nextStatus();
                  }
                },
                onLongPressStart: (_) {
                  _progressController.stop();
                  setState(() => _isPaused = true);
                },
                onLongPressEnd: (_) {
                  setState(() => _isPaused = false);
                  _progressController.forward().then((_) {
                    if (mounted) _nextStatus();
                  });
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.statuses.length,
                  itemBuilder: (context, index) {
                    final status = widget.statuses[index];
                    return _buildStatusContent(status);
                  },
                ),
              ),
            ),
            // Bottom actions: Like & Reply (WhatsApp-like)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Reply button
                  Expanded(
                    child: GestureDetector(
                      onTap: _showReplySheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'Reply to ${widget.userName}...',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Like button
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isLiked ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: _isLiked ? Colors.redAccent : Colors.white24),
                      ),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                        color: _isLiked ? Colors.redAccent : Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                  if (_likeCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$_likeCount',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(Map<String, dynamic> status) {
    final type = (status['status_type'] ?? 'text').toString();

    if (type == 'image') {
      final mediaPath = (status['media_path'] ?? '').toString();
      if (mediaPath.isEmpty) return const Center(child: Text('No media', style: TextStyle(color: Colors.white)));

      return FutureBuilder<String?>(
        future: widget.supabaseService.cacheMediaLocally(mediaPath: mediaPath, mediaMime: status['media_mime'] ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white54)));
          }
          final url = snapshot.data!;
          Widget imageWidget;
          if (url.startsWith('/') || url.startsWith('file://')) {
            final filePath = url.startsWith('file://') ? url.substring(7) : url;
            imageWidget = InteractiveViewer(child: Image.file(File(filePath), fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 64)),
            ));
          } else {
            imageWidget = InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 64)),
            ));
          }

          // [FIX #9] Show caption on image status if present
          final caption = (status['caption'] ?? '').toString().trim();
          if (caption.isNotEmpty) {
            return Stack(
              children: [
                // Full-screen image
                Positioned.fill(child: imageWidget),
                // Caption overlay at bottom
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                    child: Text(
                      caption,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            );
          }

          return imageWidget;
        },
      );
    }

    // Text status
    final content = (status['content'] ?? '').toString();
    final bgColor = (status['background_color'] ?? '#6366F1').toString();
    final isBold = status['is_bold'] == true;

    Color color;
    try {
      final hex = bgColor.replaceAll('#', '');
      color = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      color = const Color(0xFF6366F1);
    }

    return Container(
      color: color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic createdAt) {
    final dt = DateTime.tryParse((createdAt ?? '').toString());
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 19) return '${diff.inHours}h ago';
    return 'Expiring soon';
  }
}
