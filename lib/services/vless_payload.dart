class VlessPayload {
  final String uuid;
  final String server;
  final int port;
  final String host;
  final String path;
  final String sni;
  final bool allowInsecure;

  const VlessPayload({
    required this.uuid,
    required this.server,
    required this.port,
    required this.host,
    required this.path,
    required this.sni,
    required this.allowInsecure,
  });

  /// Minimal VLESS URI parser for links like:
  /// vless://UUID@server:port?allowInsecure=1&host=example.com&path=%2F&security=tls&sni=example.com&type=ws#name
  static VlessPayload fromUri(String uri) {
    final parsed = Uri.parse(uri);
    if (parsed.scheme.toLowerCase() != 'vless') {
      throw FormatException('Not a vless:// uri');
    }

    final uuid = parsed.userInfo;
    final server = parsed.host;
    final port = parsed.port == 0 ? 443 : parsed.port;

    final q = parsed.queryParameters;
    final allowInsecure = (q['allowInsecure'] ?? '0') == '1' || (q['allowInsecure'] ?? '').toLowerCase() == 'true';
    final host = q['host'] ?? q['sni'] ?? server;
    final path = q['path'] ?? '/';
    final sni = q['sni'] ?? host;

    // Basic validation
    if (uuid.isEmpty) throw FormatException('Missing UUID');
    if (server.isEmpty) throw FormatException('Missing server');

    return VlessPayload(
      uuid: uuid,
      server: server,
      port: port,
      host: host,
      path: Uri.decodeComponent(path),
      sni: sni,
      allowInsecure: allowInsecure,
    );
  }
}
