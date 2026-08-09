import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:zibashu_core/zibashu_core.dart';

/// Phase 3: fetch + store WireGuard session material securely.
/// Tunnel traffic is always WireGuard AEAD (ChaCha20-Poly1305) once applied.
/// Platform VpnService apply is the next integration step; this module never
/// permits a plaintext tunnel mode.
class WireGuardSessionClient {
  WireGuardSessionClient({
    this.baseUrl = ApiConfig.defaultBaseUrl,
    FlutterSecureStorage? storage,
    http.Client? httpClient,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _http;

  static const _keyProfile = 'flux.wg.profile';
  static const requiredProtocol = 'wireguard';

  /// Returns server security posture (no secrets).
  Future<Map<String, dynamic>?> fetchSecurity() async {
    final uri = Uri.parse('$baseUrl/api/flux/security');
    final resp = await _http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body);
    return body is Map<String, dynamic> ? body : null;
  }

  /// Request a session profile. Requires Sanctum bearer token when live.
  Future<Map<String, dynamic>?> requestSession({
    required String nodeId,
    required String bearerToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/flux/session');
    final resp = await _http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $bearerToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'node_id': nodeId}),
        )
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body);
    if (body is! Map<String, dynamic>) return null;
    if (body['ok'] != true) return null;
    if (body['protocol'] != requiredProtocol) {
      throw StateError('Refusing non-WireGuard protocol');
    }
    if (body['encrypted'] != true) {
      throw StateError('Refusing non-encrypted session');
    }
    final profile = body['profile'];
    if (profile is Map<String, dynamic>) {
      // Secure store only; never log privateKey.
      await _storage.write(key: _keyProfile, value: jsonEncode(profile));
    }
    return body;
  }

  Future<Map<String, dynamic>?> readStoredProfile() async {
    final raw = await _storage.read(key: _keyProfile);
    if (raw == null || raw.isEmpty) return null;
    final body = jsonDecode(raw);
    return body is Map<String, dynamic> ? body : null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyProfile);
  }

  /// Build wg-quick style conf from a stored profile map.
  String? toConf(Map<String, dynamic> profile) {
    final iface = profile['interface'];
    final peer = profile['peer'];
    if (iface is! Map || peer is! Map) return null;
    final sk = iface['privateKey']?.toString() ?? '';
    final pk = peer['publicKey']?.toString() ?? '';
    if (sk.isEmpty || pk.isEmpty) return null;
    if (sk.contains('REDACTED') || pk.contains('STUB')) return null;
    return '''
[Interface]
PrivateKey = $sk
Address = ${iface['address']}
DNS = ${iface['dns'] ?? '1.1.1.1'}
MTU = ${iface['mtu'] ?? 1420}

[Peer]
PublicKey = $pk
Endpoint = ${peer['endpoint']}
AllowedIPs = ${peer['allowedIps'] ?? '0.0.0.0/0, ::/0'}
PersistentKeepalive = ${peer['persistentKeepalive'] ?? 25}
''';
  }
}
