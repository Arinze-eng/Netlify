import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_service.dart';
import '../services/vpn_manager.dart';
import '../services/vpn_service.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../widgets/glass_container.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _supabase = SupabaseService();

  final _passwordController = TextEditingController();
  bool _authed = false;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _events = [];

  final _vpnConfigController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _vpnConfigController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final secret = _passwordController.text.trim();
      if (secret != SupabaseService.adminSecret) {
        throw Exception('Wrong admin password');
      }

      final data = await _supabase.adminListProfiles(secret: secret);
      final events = await _supabase.adminListAuthEvents(secret: secret, limit: 200);

      String? remoteLink;
      try {
        remoteLink = await _supabase.getRemoteVpnShareLink();
      } catch (_) {
        remoteLink = null;
      }

      if (!mounted) return;
      setState(() {
        _authed = true;
        _profiles = data;
        _events = events;
        _vpnConfigController.text = (remoteLink ?? '').trim();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (!_authed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final secret = _passwordController.text.trim();
      final data = await _supabase.adminListProfiles(secret: secret);
      final events = await _supabase.adminListAuthEvents(secret: secret, limit: 200);
      if (!mounted) return;
      setState(() {
        _profiles = data;
        _events = events;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProfiles {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _profiles;
    return _profiles.where((p) {
      final email = (p['email'] ?? '').toString().toLowerCase();
      final username = (p['username'] ?? '').toString().toLowerCase();
      final name = (p['display_name'] ?? '').toString().toLowerCase();
      final id = (p['id'] ?? '').toString().toLowerCase();
      return email.contains(q) || username.contains(q) || name.contains(q) || id.contains(q);
    }).toList();
  }

  Future<void> _grantPremium(String userId) async {
    final daysCtrl = TextEditingController(text: '30');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: Text('Grant Premium', style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User ID:\n$userId',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Days',
                labelStyle: GoogleFonts.poppins(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Grant'),
          )
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final days = int.tryParse(daysCtrl.text.trim()) ?? 30;
      await _supabase.adminGrantPremium(secret: _passwordController.text.trim(), userId: userId, days: days);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revokePremium(String userId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF203A43),
            title: Text('Revoke Premium?', style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(
              'User ID:\n$userId',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Revoke'),
              )
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _supabase.adminRevokePremium(secret: _passwordController.text.trim(), userId: userId);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeTrial(String userId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF203A43),
            title: Text('Remove Trial?', style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will immediately expire the user\'s trial period. They will need a premium subscription to continue using the app.',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'User ID:\n$userId',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove Trial'),
              )
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _supabase.adminRemoveTrial(secret: _passwordController.text.trim(), userId: userId);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setBlocked(String userId, bool blocked) async {
    final reasonCtrl = TextEditingController();

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF203A43),
            title: Text(blocked ? 'Block user' : 'Unblock user', style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('User ID:\n$userId', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                if (blocked) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      labelStyle: GoogleFonts.poppins(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(blocked ? 'Block' : 'Unblock'),
              )
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _supabase.adminSetUserBlocked(
        secret: _passwordController.text.trim(),
        userId: userId,
        blocked: blocked,
        reason: blocked ? reasonCtrl.text.trim() : null,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveVpnConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final link = _vpnConfigController.text.trim();
      if (link.isEmpty) throw Exception('VPN config cannot be empty');

      // Validate link format
      try {
        final parsed = FlutterV2ray.parseFromURL(link);
        if ((parsed.remark).isEmpty && (parsed.getFullConfiguration()).isEmpty) {
          throw Exception('Invalid V2Ray link');
        }
      } catch (e) {
        throw Exception('Invalid V2Ray link. Paste a valid vless:// or vmess:// share link.');
      }

      // Save to Supabase (remote)
      await _supabase.adminSetVpnConfig(secret: _passwordController.text.trim(), shareLink: link);

      // Also save locally immediately so VPN picks up the new config
      // This ensures the config works even when the user is offline
      await VpnService.saveProxyUri(link);

      // If VPN is currently active, restart it with the new config
      if (VpnManager.instance.isActive) {
        await VpnManager.instance.updateConfig(link, restartIfActive: true);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('VPN config updated & synced locally')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Admin', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Login', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Admin password',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.25),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _loginAdmin,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_authed ? 'Re-auth + Load' : 'Login'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12)),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (_authed) ...[
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('VPN Remote Config (V2Ray Share Link)',
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    final link = await _supabase.getRemoteVpnShareLink();
                                    if (!mounted) return;
                                    setState(() => _vpnConfigController.text = (link ?? '').trim());
                                  },
                            icon: const Icon(Icons.download_rounded),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _vpnConfigController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Paste vless:// or vmess:// here',
                          hintStyle: GoogleFonts.poppins(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.25),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _saveVpnConfig,
                          child: const Text('Save VPN Config'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Users (Signups + Last Seen)',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, UUID...',
                          hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.25),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_filteredProfiles.isEmpty)
                        Text('No users yet', style: GoogleFonts.poppins(color: Colors.white60))
                      else
                        ..._filteredProfiles.take(200).map((p) {
                          final id = (p['id'] ?? '').toString();
                          final email = (p['email'] ?? '').toString();
                          final username = (p['username'] ?? '').toString();
                          final name = (p['display_name'] ?? '').toString();
                          final lastSeen = (p['last_seen'] ?? '').toString();
                          final createdAt = (p['created_at'] ?? '').toString();
                          final subscribed = (p['is_subscribed'] == true);
                          final expiry = (p['subscription_expiry'] ?? '').toString();
                          final blocked = (p['is_blocked'] == true);
                          final blockedReason = (p['blocked_reason'] ?? '').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name.isNotEmpty ? '$name  ($username)' : username,
                                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: subscribed ? Colors.green.withOpacity(0.18) : Colors.orange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: subscribed ? Colors.green : Colors.orange),
                                      ),
                                      child: Text(
                                        subscribed ? 'PREMIUM' : 'TRIAL',
                                        style: GoogleFonts.poppins(
                                          color: subscribed ? Colors.greenAccent : Colors.orangeAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (blocked) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: Colors.redAccent),
                                        ),
                                        child: Text(
                                          'BLOCKED',
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Email: $email', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                                Text('User ID: $id', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                                Text('Signed up: $createdAt', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                                Text('Last seen: $lastSeen', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                                if (blockedReason.isNotEmpty)
                                  Text('Blocked reason: $blockedReason',
                                      style: GoogleFonts.poppins(color: Colors.redAccent.withOpacity(0.85), fontSize: 11)),
                                if (expiry.isNotEmpty)
                                  Text('Premium expiry: $expiry',
                                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                                const SizedBox(height: 10),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: _loading ? null : () => _grantPremium(id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                              ),
                                              child: const Text('Grant Premium'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: _loading || !subscribed ? null : () => _revokePremium(id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                              ),
                                              child: const Text('Revoke Premium'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: _loading || blocked ? null : () => _setBlocked(id, true),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                side: BorderSide(color: Colors.redAccent.withOpacity(0.7)),
                                              ),
                                              child: const Text('Block'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: _loading || !blocked ? null : () => _setBlocked(id, false),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.greenAccent,
                                                side: BorderSide(color: Colors.greenAccent.withOpacity(0.6)),
                                              ),
                                              child: const Text('Unblock'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Remove Trial button — admin can remove trial from any user
                                    SizedBox(
                                      width: double.infinity,
                                      height: 40,
                                      child: OutlinedButton(
                                        onPressed: _loading ? null : () => _removeTrial(id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orangeAccent,
                                          side: BorderSide(color: Colors.orangeAccent.withOpacity(0.6)),
                                        ),
                                        child: const Text('Remove Trial'),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        })
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Auth Events (Sign-ins)',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      if (_events.isEmpty)
                        Text('No events yet', style: GoogleFonts.poppins(color: Colors.white60))
                      else
                        ..._events.take(120).map((e) {
                          final event = (e['event'] ?? '').toString();
                          final uid = (e['user_id'] ?? '').toString();
                          final at = (e['created_at'] ?? '').toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text('$at  •  $event  •  $uid',
                                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                          );
                        })
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
