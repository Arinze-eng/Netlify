import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VpnModuleApp());
}

class VpnModuleApp extends StatelessWidget {
  const VpnModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CDN-NETCHAT VPN',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF22C55E),
        useMaterial3: true,
      ),
      home: const VpnHomePage(),
    );
  }
}

class VpnHomePage extends StatefulWidget {
  const VpnHomePage({super.key});

  @override
  State<VpnHomePage> createState() => _VpnHomePageState();
}

class _VpnHomePageState extends State<VpnHomePage> {
  late final V2ray _v2ray;

  final _linkController = TextEditingController();
  String _state = 'IDLE';
  String? _error;
  String? _testResult;
  bool _starting = false;

  static const _defaultLink =
      'vless://UUID@your-domain.com:443?encryption=none&security=tls&type=ws&host=your-domain.com&path=%2F&sni=your-domain.com#MyVLESS';

  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    _v2ray = V2ray(onStatusChanged: (status) {
      final s = (status.state ?? status.toString()).toString();
      if (mounted) setState(() => _state = s);
    });

    () async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('proxy_link');
      _linkController.text = (saved != null && saved.trim().isNotEmpty) ? saved : _defaultLink;

      // Init core
      try {
        await _v2ray.initialize(
          notificationIconResourceType: 'mipmap',
          notificationIconResourceName: 'ic_launcher',
        );
      } catch (e) {
        if (mounted) setState(() => _error = 'Init failed: $e');
      }

      // Handle incoming deep links from the main app
      try {
        final initial = await _appLinks.getInitialLink();
        if (initial != null) {
          await _handleIncomingLink(initial);
        }
      } catch (_) {
        // ignore
      }

      _appLinks.uriLinkStream.listen((uri) async {
        await _handleIncomingLink(uri);
      });
    }();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('proxy_link', _linkController.text.trim());
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    // Expected:
    // cdnnetchatvpn://vpn/start?link=<base64url>&autoconnect=1
    if (!mounted) return;

    try {
      if (uri.scheme != 'cdnnetchatvpn') return;

      final path = uri.path;
      final q = uri.queryParameters;

      final b64 = q['link'];
      if (b64 != null && b64.isNotEmpty) {
        final decoded = utf8.decode(base64Url.decode(b64));
        setState(() {
          _linkController.text = decoded;
          _error = null;
        });
        await _save();
      }

      final autoconnect = (q['autoconnect'] ?? '0') == '1';
      if (path == '/start' && autoconnect) {
        await _connect();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Deep link error: $e');
    }
  }

  Future<void> _connect() async {
    setState(() {
      _starting = true;
      _error = null;
      _testResult = null;
    });

    try {
      final link = _linkController.text.trim();
      if (link.isEmpty) throw Exception('Paste a vless:// or vmess:// link first');

      await _save();

      final ok = await _v2ray.requestPermission();
      if (!ok) throw Exception('VPN permission denied');

      final parsed = V2ray.parseFromURL(link);
      await _v2ray.startV2Ray(
        remark: parsed.remark ?? 'CDN-NETCHAT VPN',
        config: parsed.getFullConfiguration(),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _error = null;
      _testResult = null;
    });

    try {
      await _v2ray.stopV2Ray();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _testInternet() async {
    setState(() {
      _testResult = null;
      _error = null;
    });

    try {
      // Less likely to be blocked than 1.1.1.1 on some mobile networks
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse('https://clients3.google.com/generate_204'));
      final res = await req.close();
      setState(() => _testResult = 'HTTP ${res.statusCode} (expected 204)');
    } catch (e) {
      setState(() => _testResult = 'FAILED: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _state.toUpperCase().contains('CONNECTED');

    return Scaffold(
      appBar: AppBar(
        title: const Text('CDN-NETCHAT VPN Module'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'Status',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core state: $_state'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton(
                      onPressed: _starting ? null : (connected ? _disconnect : _connect),
                      child: Text(connected ? 'Disconnect' : 'Connect'),
                    ),
                    OutlinedButton(
                      onPressed: _starting ? null : _testInternet,
                      child: const Text('Test Internet'),
                    ),
                    OutlinedButton(
                      onPressed: _starting
                          ? null
                          : () async {
                              await _save();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved link')),
                              );
                            },
                      child: const Text('Save Link'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'VLESS/VMESS Link',
            subtitle: 'Paste the same link that works in v2rayNG',
            child: TextField(
              controller: _linkController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'vless://... or vmess://...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            _Card(
              title: 'Error',
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          if (_testResult != null)
            _Card(
              title: 'Test result',
              child: Text(_testResult!),
            ),
          const SizedBox(height: 12),
          _Card(
            title: 'How to use',
            child: const Text(
              '1) Paste vless:// or vmess:// link\n'
              '2) Tap Connect and allow VPN permission\n'
              '3) Tap Test Internet\n\n'
              'If this module connects but your main app doesn\'t, the issue is your main app build/native integration, not the server.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
