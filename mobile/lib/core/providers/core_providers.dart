import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../network/dio_client.dart';
import '../services/device_id_service.dart';
import '../storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService(ref.watch(secureStorageProvider));
});

final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(
    secureStorage: secureStorage,
    onAuthFailure: () async {
      await secureStorage.clearSession();
      ref.read(sessionExpiredProvider.notifier).state = true;
    },
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());