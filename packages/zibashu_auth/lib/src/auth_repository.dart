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

  /// Device-code login for any ziBashu APK (Seru uses `/api/mobile/auth/device`).
  Future<Result<DeviceAuthChallenge>> startDeviceAuth({
    String path = '/api/mobile/auth/device',
    String clientName = 'Seru Android',
    String? deviceId,
  }) async {
    if (config.demoMode) {
      final page = path.contains('/flux/')
          ? '${config.baseUrl}/flux/auth/device'
          : '${config.baseUrl}/seru/auth/device';
      return Ok(DeviceAuthChallenge(
        deviceCode: 'demo-device-code',
        userCode: 'DEMO-CODE',
        verificationUri: page,
        verificationUriComplete: '$page?user_code=DEMO-CODE',
        expiresIn: 600,
        interval: 2,
      ));
    }

    final result = await _client.post(
      path,
      data: {
        'client_name': clientName,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      },
    );

    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok(:final data):
        final body = data.data;
        if (body is! Map) {
          return const Err('Unexpected auth start response');
        }
        final deviceCode = body['device_code']?.toString() ?? '';
        final userCode = body['user_code']?.toString() ?? '';
        if (deviceCode.isEmpty) {
          return const Err('No device_code from control plane');
        }
        var ver = body['verification_uri']?.toString() ??
            '${config.baseUrl}/seru/auth/device';
        var complete = body['verification_uri_complete']?.toString() ?? '';
        if (complete.isEmpty) {
          complete = userCode.isEmpty
              ? ver
              : '$ver${ver.contains('?') ? '&' : '?'}user_code=${Uri.encodeComponent(userCode)}';
        }
        if (ver.startsWith('http://')) {
          ver = 'https://${ver.substring(7)}';
        }
        if (complete.startsWith('http://')) {
          complete = 'https://${complete.substring(7)}';
        }
        return Ok(DeviceAuthChallenge(
          deviceCode: deviceCode,
          userCode: userCode,
          verificationUri: ver,
          verificationUriComplete: complete,
          expiresIn: (body['expires_in'] is int)
              ? body['expires_in'] as int
              : int.tryParse('${body['expires_in']}') ?? 600,
          interval: (body['interval'] is int)
              ? body['interval'] as int
              : int.tryParse('${body['interval']}') ?? 3,
        ));
    }
  }

  Future<Result<DeviceAuthPoll>> pollDeviceAuth(
    String deviceCode, {
    String path = '/api/mobile/auth/device/poll',
  }) async {
    if (config.demoMode) {
      const token = 'demo-token';
      await _store.writeToken(token);
      await _store.writeProfile(name: 'demo', email: 'demo@zibashu4.com');
      _client.setAuthToken(token);
      return Ok(DeviceAuthPoll(
        status: 'approved',
        session: const AuthSession(
          token: token,
          name: 'demo',
          email: 'demo@zibashu4.com',
        ),
      ));
    }

    final result = await _client.post(path, data: {'device_code': deviceCode});

    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok(:final data):
        final body = data.data;
        if (body is! Map) {
          return const Err('Unexpected auth poll response');
        }
        final status = body['status']?.toString() ?? 'pending';
        if (status == 'approved') {
          final token = body['token']?.toString();
          if (token == null || token.isEmpty) {
            return const Err('No token in approve response');
          }
          final user = body['user'];
          final name = user is Map ? user['name']?.toString() : null;
          final email = user is Map ? user['email']?.toString() : null;
          await _store.writeToken(token);
          await _store.writeProfile(name: name, email: email);
          _client.setAuthToken(token);
          return Ok(DeviceAuthPoll(
            status: 'approved',
            session: AuthSession(token: token, name: name, email: email),
          ));
        }
        if (status == 'pending') {
          final interval = (body['interval'] is int)
              ? body['interval'] as int
              : int.tryParse('${body['interval']}') ?? 3;
          return Ok(DeviceAuthPoll(status: 'pending', interval: interval));
        }
        return Ok(DeviceAuthPoll(
          status: status,
          reason: body['reason']?.toString() ?? status,
        ));
    }
  }

  /// Primary production path: start ziBashu device-code (browser approve).
  Future<Result<DeviceAuthChallenge>> startZiBashuDeviceAuth({
    String clientName = 'Flux Android',
    String? deviceId,
  }) async {
    return startDeviceAuth(
      path: '/api/flux/auth/device',
      clientName: clientName,
      deviceId: deviceId,
    );
  }

  /// Poll until ziBashu web approve returns a Sanctum token (or pending/expired).
  Future<Result<DeviceAuthPoll>> pollZiBashuDeviceAuth(String deviceCode) async {
    return pollDeviceAuth(deviceCode, path: '/api/flux/auth/device/poll');
  }

  /// Legacy password login (lab only — not used by Flux primary UX).
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

class DeviceAuthChallenge {
  const DeviceAuthChallenge({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.verificationUriComplete,
    this.expiresIn = 600,
    this.interval = 3,
  });

  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final String verificationUriComplete;
  final int expiresIn;
  final int interval;
}

class DeviceAuthPoll {
  const DeviceAuthPoll({
    required this.status,
    this.session,
    this.reason,
    this.interval = 3,
  });

  final String status;
  final AuthSession? session;
  final String? reason;
  final int interval;
}
