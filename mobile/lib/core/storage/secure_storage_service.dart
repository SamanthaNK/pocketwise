import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey = 'device_id';
  static const _hasHydratedKey = 'has_hydrated';

  Future<void> writeTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  Future<void> writeDeviceId(String id) => _storage.write(key: _deviceIdKey, value: id);
  Future<String?> readDeviceId() => _storage.read(key: _deviceIdKey);

  Future<void> markHydrated() => _storage.write(key: _hasHydratedKey, value: 'true');
  Future<bool> hasHydrated() async => (await _storage.read(key: _hasHydratedKey)) == 'true';

  Future<void> clearSession() async {
    await clearTokens();
    await _storage.delete(key: _hasHydratedKey);
  }
}