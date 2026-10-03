import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the backend tokens in the platform keystore/keychain.
class TokenStorage {
  TokenStorage({this.storage = const FlutterSecureStorage()});

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage storage;

  Future<String?> readAccessToken() => storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => storage.read(key: _refreshKey);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storage.write(key: _accessKey, value: accessToken);
    await storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    await storage.delete(key: _accessKey);
    await storage.delete(key: _refreshKey);
  }
}
