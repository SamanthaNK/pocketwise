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
    await _saveTokensAndHydrate(data);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _authApi.login(email: email, password: password);
    await _saveTokensAndHydrate(data);
  }

  Future<void> _saveTokensAndHydrate(Map<String, dynamic> tokenData) async {
    await _secureStorage.writeTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    await _hydrationService.hydrateAll();
    await _secureStorage.markHydrated();
  }

  Future<void> logout() async {
    await _secureStorage.clearSession();
    await _appDatabase.clearAllData();
  }

  Future<bool> hasActiveSession() => _secureStorage.hasSession();

  Future<void> hydrateIfNeeded() async {
    if (!(await _secureStorage.hasHydrated())) {
      await _hydrationService.hydrateAll();
      await _secureStorage.markHydrated();
    }
  }
}