import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/feature_providers.dart';
import '../data/debt_api.dart';
import '../data/debt_local_repository.dart';
import '../models/debt_model.dart';

final debtsProvider = FutureProvider.autoDispose<List<DebtModel>>((ref) {
  return ref.watch(debtLocalRepositoryProvider).getAll();
});

class DebtWriteController {
  DebtWriteController(this._repo, this._api);
  final DebtLocalRepository _repo;
  final DebtApi _api;

  Future<void> createDebt({
    required String personName,
    required int amount,
    required String direction,
    DateTime? dueDate,
    String? note,
  }) async {
    final debt = DebtModel(
      clientGeneratedId: const Uuid().v4(),
      serverId: null,
      personName: personName,
      amount: amount,
      direction: direction,
      dueDate: dueDate,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      isSettled: false,
      settledAt: null,
      isDeleted: false,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _repo.create(debt);
  }

  Future<void> updateDebt(
    DebtModel existing, {
    required String personName,
    required int amount,
    required String direction,
    DateTime? dueDate,
    String? note,
  }) async {
    final updated = DebtModel(
      clientGeneratedId: existing.clientGeneratedId,
      serverId: existing.serverId,
      personName: personName,
      amount: amount,
      direction: direction,
      dueDate: dueDate,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      isSettled: existing.isSettled,
      settledAt: existing.settledAt,
      isDeleted: false,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _repo.update(updated);
  }

  Future<void> deleteDebt(String clientGeneratedId) => _repo.softDelete(clientGeneratedId);

  Future<void> settleDebt(DebtModel debt) async {
    if (debt.serverId == null) {
      throw Exception("This debt hasn't synced yet. Connect to the internet, wait a moment, then try again.");
    }
    final settled = await _api.settle(debt.serverId!);
    await _repo.replaceWithServerCopy(settled);
  }
}

final debtWriteControllerProvider = Provider((ref) {
  return DebtWriteController(ref.watch(debtLocalRepositoryProvider), ref.watch(debtApiProvider));
});