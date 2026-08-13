import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

class PrivacyModeController extends StateNotifier<bool> {
  PrivacyModeController(this._ref) : super(false) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    state = await _ref.read(secureStorageProvider).readPrivacyMode();
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _ref.read(secureStorageProvider).writePrivacyMode(next);
    try {
      await _ref.read(dioClientProvider).dio.put('/users/me/privacy-mode', data: {'enabled': next});
    } catch (_) {
      // Best-effort only — the local toggle already succeeded.
    }
  }
}

final privacyModeProvider = StateNotifierProvider<PrivacyModeController, bool>((ref) {
  return PrivacyModeController(ref);
});