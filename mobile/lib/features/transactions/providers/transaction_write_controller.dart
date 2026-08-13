import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/feature_providers.dart';
import '../data/transaction_local_repository.dart';
import '../models/transaction_model.dart';

class TransactionWriteController {
  TransactionWriteController(this._repo);
  final TransactionLocalRepository _repo;

  Future<void> createTransaction({
    required String categoryId,
    String? paymentMethodId,
    required String type,
    required int amount,
    String? description,
    required DateTime date,
  }) async {
    final transaction = TransactionModel(
      clientGeneratedId: const Uuid().v4(),
      serverId: null,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      type: type,
      amount: amount,
      description: (description == null || description.trim().isEmpty) ? null : description.trim(),
      transactionDate: date,
      isDeleted: false,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _repo.create(transaction);
  }

  Future<void> updateTransaction(
    TransactionModel existing, {
    required String categoryId,
    required String type,
    String? paymentMethodId,
    bool clearPaymentMethod = false,
    required int amount,
    String? description,
    required DateTime date,
  }) async {
    final updated = TransactionModel(
      clientGeneratedId: existing.clientGeneratedId,
      serverId: existing.serverId,
      categoryId: categoryId,
      paymentMethodId: clearPaymentMethod ? null : paymentMethodId,
      type: type,
      amount: amount,
      description: (description == null || description.trim().isEmpty) ? null : description.trim(),
      transactionDate: date,
      isDeleted: false,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _repo.update(updated);
  }

  Future<void> deleteTransaction(String clientGeneratedId) => _repo.softDelete(clientGeneratedId);
}

final transactionWriteControllerProvider = Provider((ref) {
  return TransactionWriteController(ref.watch(transactionLocalRepositoryProvider));
});