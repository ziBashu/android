import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure on-device Sanctum token storage.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _tokenKey = 'zibashu_sanctum_token';
  static const _userNameKey = 'zibashu_user_name';
  static const _userEmailKey = 'zibashu_user_email';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> writeProfile({String? name, String? email}) async {
    if (name != null) {
      await _storage.write(key: _userNameKey, value: name);
    }
    if (email != null) {
      await _storage.write(key: _userEmailKey, value: email);
    }
  }

  Future<String?> readName() => _storage.read(key: _userNameKey);

  Future<String?> readEmail() => _storage.read(key: _userEmailKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }
}
