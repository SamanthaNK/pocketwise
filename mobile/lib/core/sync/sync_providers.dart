import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../providers/feature_providers.dart';
import 'sync_manager.dart';
import 'sync_status.dart';

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(
    dio: ref.watch(dioClientProvider).dio,
    categoryRepo: ref.watch(categoryLocalRepositoryProvider),
    paymentMethodRepo: ref.watch(paymentMethodLocalRepositoryProvider),
    transactionRepo: ref.watch(transactionLocalRepositoryProvider),
    savingsGoalRepo: ref.watch(savingsGoalLocalRepositoryProvider),
    savingsContributionRepo: ref.watch(savingsContributionLocalRepositoryProvider),
    debtRepo: ref.watch(debtLocalRepositoryProvider),
    onStatusChange: (status) => ref.read(syncStatusProvider.notifier).state = status,
  );
});

class ConnectivitySyncTrigger {
  ConnectivitySyncTrigger(this._ref) {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) _ref.read(syncManagerProvider).syncNow();
    });
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (_) => _ref.read(syncManagerProvider).syncNow());
    _ref.read(syncManagerProvider).syncNow();
  }

  final Ref _ref;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  late final Timer _periodicTimer;

  void dispose() {
    _subscription.cancel();
    _periodicTimer.cancel();
  }
}

final connectivitySyncTriggerProvider = Provider<ConnectivitySyncTrigger>((ref) {
  final trigger = ConnectivitySyncTrigger(ref);
  ref.onDispose(trigger.dispose);
  return trigger;
});