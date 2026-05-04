class ProxyPayload {
  final String type; // 'vless' | 'vmess'
  final String uuid;
  final String server;
  final int port;

  // Common WS/TLS params
  final String host;
  final String path;
  final String sni;
  final bool tls;
  final bool allowInsecure;

  // VMess extras
  final String security; // e.g. 'auto'
  final int alterId;

  const ProxyPayload({
    required this.type,
    required this.uuid,
    required this.server,
    required this.port,
    required this.host,
    required this.path,
    required this.sni,
    required this.tls,
    required this.allowInsecure,
    required this.security,
    required this.alterId,
  });
}
