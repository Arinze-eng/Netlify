import 'dart:convert';

import 'proxy_payload.dart';

class ProxyPayloadParser {
  /// Supports:
  /// - vless://UUID@server:port?allowInsecure=1&host=...&path=...&security=tls&sni=...&type=ws
  /// - vmess://(base64(json)) where json is V2RayN style
  static ProxyPayload fromUri(String uri) {
    final parsed = Uri.parse(uri.trim());
    final scheme = parsed.scheme.toLowerCase();

    if (scheme == 'vless') {
      final uuid = parsed.userInfo;
      final server = parsed.host;
      final port = parsed.port == 0 ? 443 : parsed.port;

      final q = parsed.queryParameters;
      final allowInsecure = (q['allowInsecure'] ?? '0') == '1' || (q['allowInsecure'] ?? '').toLowerCase() == 'true';
      final host = q['host'] ?? q['sni'] ?? server;
      final path = Uri.decodeComponent(q['path'] ?? '/');
      final sni = q['sni'] ?? host;
      final tls = (q['security'] ?? '').toLowerCase() == 'tls';

      if (uuid.isEmpty) throw FormatException('Missing UUID');
      if (server.isEmpty) throw FormatException('Missing server');

      return ProxyPayload(
        type: 'vless',
        uuid: uuid,
        server: server,
        port: port,
        host: host,
        path: path,
        sni: sni,
        // Most VLESS WS links used here are TLS; default to true when not specified.
        tls: tls || (q['security'] ?? '').isEmpty,
        allowInsecure: allowInsecure,
        security: 'auto',
        alterId: 0,
      );
    }

    if (scheme == 'vmess') {
      // vmess links are typically base64(JSON)
      final b64 = uri.substring(uri.indexOf('://') + 3).trim();
      final normalized = b64.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(normalized.length + ((4 - normalized.length % 4) % 4), '=');
      final jsonStr = utf8.decode(base64Decode(padded));
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;

      final server = (obj['add'] ?? '').toString();
      final port = int.tryParse((obj['port'] ?? '443').toString()) ?? 443;
      final uuid = (obj['id'] ?? '').toString();
      final alterId = int.tryParse((obj['aid'] ?? '0').toString()) ?? 0;
      final security = (obj['scy'] ?? obj['security'] ?? 'auto').toString();

      final net = (obj['net'] ?? 'ws').toString();
      final host = (obj['host'] ?? server).toString();
      final path = (obj['path'] ?? '/').toString();
      final tlsStr = (obj['tls'] ?? '').toString().toLowerCase();
      final tls = tlsStr == 'tls' || tlsStr == 'reality';
      final sni = (obj['sni'] ?? obj['servername'] ?? host).toString();

      if (uuid.isEmpty) throw FormatException('Missing id (uuid) in vmess json');
      if (server.isEmpty) throw FormatException('Missing add (server) in vmess json');
      if (net.toLowerCase() != 'ws') {
        throw FormatException('Only ws vmess is supported in this app build. net=$net');
      }

      return ProxyPayload(
        type: 'vmess',
        uuid: uuid,
        server: server,
        port: port,
        host: host,
        path: path,
        sni: sni,
        tls: tls,
        allowInsecure: false,
        security: security,
        alterId: alterId,
      );
    }

    throw FormatException('Unsupported URI scheme: ${parsed.scheme}');
  }
}
