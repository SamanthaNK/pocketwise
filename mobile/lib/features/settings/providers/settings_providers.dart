import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/settings_api.dart';

final settingsApiProvider = Provider((ref) => SettingsApi(ref.watch(dioClientProvider).dio));

final currentUserProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(settingsApiProvider).getMe();
});