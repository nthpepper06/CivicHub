import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_token_storage.dart';

class SecureAuthTokenStorage implements AuthTokenStorage {
  SecureAuthTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'civichub_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);

  @override
  Future<bool> hasAccessToken() async {
    return (await readAccessToken())?.isNotEmpty ?? false;
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }
}
