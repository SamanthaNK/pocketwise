import 'dart:async';

import '../../../core/database/app_database.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/sync/hydration_service.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi authApi,
    required SecureStorageService secureStorage,
    required HydrationService hydrationService,
    required AppDatabase appDatabase,
  })  : _authApi = authApi,
        _secureStorage = secureStorage,
        _hydrationService = hydrationService,
        _appDatabase = appDatabase;

  final AuthApi _authApi;
  final SecureStorageService _secureStorage;
  final HydrationService _hydrationService;
  final AppDatabase _appDatabase;

  Future<void> register({required String name, required String email, required String password}) async {
    final data = await _authApi.register(name: name, email: email, password: password);
    await _saveTokens(data);
    unawaited(hydrateInBackground());
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _authApi.login(email: email, password: password);
    await _saveTokens(data);
    unawaited(hydrateInBackground());
  }

  Future<void> _saveTokens(Map<String, dynamic> tokenData) async {
    await _secureStorage.writeTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
  }

  Future<void> logout() async {
    await _secureStorage.clearSession();
    await _appDatabase.clearAllData();
  }

  Future<bool> hasActiveSession() => _secureStorage.hasSession();

  /// Pulls server data into the local database if it hasn't been hydrated yet.
  ///
  /// Deliberately swallows errors: hydration is best-effort background work
  /// that must never fail login/signup or bounce an authenticated user back
  /// to the login screen. A failed attempt is simply retried on the next
  /// call (next login, or next app launch via the splash screen).
  Future<void> hydrateInBackground() async {
    try {
      if (!(await _secureStorage.hasHydrated())) {
        await _hydrationService.hydrateAll();
        await _secureStorage.markHydrated();
      }
    } catch (_) {
      // Best-effort; will retry on the next call.
    }
  }
}