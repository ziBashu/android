import 'package:zibashu_core/zibashu_core.dart';

import 'auth_session.dart';
import 'token_store.dart';

/// Login / session lifecycle for mobile apps.
///
/// Live mode expects Laravel `POST /api/mobile/login` returning:
/// `{ "token": "...", "user": { "name": "...", "email": "..." } }`
///
/// Demo mode accepts any non-empty credentials and stores a local token.
class AuthRepository {
  AuthRepository({
    required this.config,
    TokenStore? store,
    ApiClient? client,
  })  : _store = store ?? TokenStore(),
        _client = client ?? ApiClient(config);

  final ApiConfig config;
  final TokenStore _store;
  final ApiClient _client;

  Future<AuthSession?> restore() async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return null;
    _client.setAuthToken(token);
    return AuthSession(
      token: token,
      name: await _store.readName(),
      email: await _store.readEmail(),
    );
  }

  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    if (config.demoMode) {
      if (email.trim().isEmpty || password.isEmpty) {
        return const Err('Email and password are required');
      }
      const token = 'demo-token';
      final name = email.split('@').first;
      await _store.writeToken(token);
      await _store.writeProfile(name: name, email: email);
      _client.setAuthToken(token);
      return Ok(AuthSession(token: token, name: name, email: email));
    }

    final result = await _client.post(
      '/api/mobile/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'android',
      },
    );

    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok(:final data):
        final body = data.data;
        if (body is! Map) {
          return const Err('Unexpected login response');
        }
        final token = body['token']?.toString();
        if (token == null || token.isEmpty) {
          return const Err('No token in login response');
        }
        final user = body['user'];
        final name = user is Map ? user['name']?.toString() : null;
        final userEmail = user is Map ? user['email']?.toString() : email;
        await _store.writeToken(token);
        await _store.writeProfile(name: name, email: userEmail);
        _client.setAuthToken(token);
        return Ok(AuthSession(token: token, name: name, email: userEmail));
    }
  }

  Future<void> logout() async {
    await _store.clear();
    _client.setAuthToken(null);
  }

  ApiClient get client => _client;
}
