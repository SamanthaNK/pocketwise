import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/feature_providers.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';

final authApiProvider = Provider((ref) => AuthApi(ref.watch(dioClientProvider).dio));

final authRepositoryProvider = Provider((ref) => AuthRepository(
      authApi: ref.watch(authApiProvider),
      secureStorage: ref.watch(secureStorageProvider),
      hydrationService: ref.watch(hydrationServiceProvider),
      appDatabase: ref.watch(appDatabaseProvider),
    ));