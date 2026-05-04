import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../shared/widgets/glass_container.dart';
import 'group_chat_room_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const CreateGroupScreen({super.key, required this.currentUser});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _supabaseService = SupabaseService();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _supabaseService.listProfiles();
      if (mounted) {
        setState(() {
          _allUsers = users.where((u) => u['id'] != widget.currentUser['id']).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final groupId = await _supabaseService.createGroup(
        name: name,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        memberIds: _selectedUserIds.toList(),
      );

      if (mounted) {
        // Navigate to group chat room
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatRoomScreen(
              group: {
                'group_id': groupId,
                'group_name': name,
                'group_description': _descController.text.trim(),
                'member_count': _selectedUserIds.length + 1,
              },
              currentUser: widget.currentUser,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchController.text.trim().toUpperCase();
    final filtered = _allUsers.where((u) {
      if (q.isEmpty) return true;
      final username = (u['username'] ?? '').toString().toUpperCase();
      final email = (u['email'] ?? '').toString().toUpperCase();
      final name = (u['display_name'] ?? '').toString().toUpperCase();
      return username.contains(q) || email.contains(q) || name.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create Group', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Create', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group icon placeholder
            Center(
              child: GestureDetector(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.3),
                  child: const Icon(Icons.group_rounded, color: Colors.white70, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Group name
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Group name',
                      hintStyle: GoogleFonts.poppins(color: Colors.white30),
                      prefixIcon: const Icon(Icons.group_rounded, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Group description (optional)',
                      hintStyle: GoogleFonts.poppins(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add members
            Row(
              children: [
                Text('Add Members', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(width: 8),
                if (_selectedUserIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_selectedUserIds.length} selected',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Search
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search users by name, UUID or email…',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),

            // Selected members chips
            if (_selectedUserIds.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedUserIds.map((id) {
                  Map<String, dynamic>? user;
                  try { user = _allUsers.firstWhere((u) => u['id'] == id); } catch (_) {}
                  final name = (user?['display_name'] ?? user?['username'] ?? 'User').toString();
                  return Chip(
                    label: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.3),
                    deleteIconColor: Colors.white54,
                    onDeleted: () => setState(() => _selectedUserIds.remove(id)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // User list
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (filtered.isEmpty)
              Center(child: Text('No users found', style: GoogleFonts.poppins(color: Colors.white54)))
            else
              ...filtered.map((u) {
                final id = (u['id'] ?? '').toString();
                final isSelected = _selectedUserIds.contains(id);
                final displayName = (u['display_name'] ?? '').toString().trim();
                final username = (u['username'] ?? '').toString();
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : Text(((displayName.isNotEmpty ? displayName : username).isNotEmpty ? (displayName.isNotEmpty ? displayName : username)[0].toUpperCase() : 'U'), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    displayName.isNotEmpty ? '$displayName ($username)' : username,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(u['email'] ?? '', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedUserIds.remove(id);
                      } else {
                        _selectedUserIds.add(id);
                      }
                    });
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
