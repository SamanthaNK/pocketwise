import 'package:dio/dio.dart';
import '../../features/categories/data/category_local_repository.dart';
import '../../features/payment_methods/data/payment_method_local_repository.dart';
import '../../features/savings/data/savings_contribution_local_repository.dart';
import '../../features/savings/data/savings_goal_local_repository.dart';
import '../../features/debts/data/debt_local_repository.dart';
import '../../features/transactions/data/transaction_local_repository.dart';
import 'sync_status.dart';

class SyncManager {
  SyncManager({
    required this.dio,
    required this.categoryRepo,
    required this.paymentMethodRepo,
    required this.transactionRepo,
    required this.savingsGoalRepo,
    required this.savingsContributionRepo,
    required this.debtRepo,
    required this.onStatusChange,
  });

  final Dio dio;
  final CategoryLocalRepository categoryRepo;
  final PaymentMethodLocalRepository paymentMethodRepo;
  final TransactionLocalRepository transactionRepo;
  final SavingsGoalLocalRepository savingsGoalRepo;
  final SavingsContributionLocalRepository savingsContributionRepo;
  final DebtLocalRepository debtRepo;
  final void Function(SyncStatus) onStatusChange;

  bool _isSyncing = false;

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    onStatusChange(SyncStatus.syncing);

    try {
      await _syncPhaseOne();
      await _syncPhaseTwoContributions();
      onStatusChange(SyncStatus.idle);
    } catch (_) {
      onStatusChange(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPhaseOne() async {
    final unsyncedTransactions = await transactionRepo.getUnsynced();
    final unsyncedGoals = await savingsGoalRepo.getUnsynced();
    final unsyncedDebts = await debtRepo.getUnsynced();

    if (unsyncedTransactions.isEmpty && unsyncedGoals.isEmpty && unsyncedDebts.isEmpty) return;

    final transactionItems = <Map<String, dynamic>>[];
    for (final t in unsyncedTransactions) {
      final category = await categoryRepo.getByClientId(t.categoryId);
      if (category?.serverId == null) continue; // not resolvable yet, retry later
      final paymentMethodServerId = t.paymentMethodId == null ? null : await _findPaymentMethodServerId(t.paymentMethodId!);
      transactionItems.add({
        'client_generated_id': t.clientGeneratedId,
        'category_id': category!.serverId,
        'payment_method_id': paymentMethodServerId,
        'amount': t.amount,
        'description': t.description,
        'transaction_date': t.transactionDate.toIso8601String().split('T').first,
        'updated_at': t.updatedAt.toIso8601String(),
      });
    }

    if (transactionItems.isEmpty && unsyncedGoals.isEmpty && unsyncedDebts.isEmpty) return;

    final body = {
      'transactions': transactionItems,
      'categories': [],
      'payment_methods': [],
      'budgets': [],
      'savings_goals': unsyncedGoals
          .map((g) => {
                'client_generated_id': g.clientGeneratedId,
                'name': g.name,
                'target_amount': g.targetAmount,
                'target_date': g.targetDate?.toIso8601String().split('T').first,
                'updated_at': g.updatedAt.toIso8601String(),
              })
          .toList(),
      'savings_contributions': [],
      'debts': unsyncedDebts
          .map((d) => {
                'client_generated_id': d.clientGeneratedId,
                'person_name': d.personName,
                'amount': d.amount,
                'direction': d.direction,
                'due_date': d.dueDate?.toIso8601String().split('T').first,
                'note': d.note,
                'updated_at': d.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    final response = await dio.post('/sync/batch', data: body);
    final data = response.data as Map<String, dynamic>;

    for (final result in (data['transactions'] as List)) {
      final map = result as Map<String, dynamic>;
      final tx = map['transaction'] as Map<String, dynamic>;
      await transactionRepo.markSynced(map['client_generated_id'] as String,
          serverId: tx['id'] as int?, updatedAt: DateTime.parse(tx['updated_at'] as String));
    }
    for (final result in (data['savings_goals'] as List)) {
      final map = result as Map<String, dynamic>;
      final goal = map['savings_goal'] as Map<String, dynamic>;
      await savingsGoalRepo.markSynced(map['client_generated_id'] as String,
          serverId: goal['id'] as int?, updatedAt: DateTime.parse(goal['updated_at'] as String));
    }
    for (final result in (data['debts'] as List)) {
      final map = result as Map<String, dynamic>;
      final debt = map['debt'] as Map<String, dynamic>;
      await debtRepo.markSynced(map['client_generated_id'] as String,
          serverId: debt['id'] as int?, updatedAt: DateTime.parse(debt['updated_at'] as String));
    }
  }

  Future<void> _syncPhaseTwoContributions() async {
    final unsyncedContributions = await savingsContributionRepo.getUnsynced();
    if (unsyncedContributions.isEmpty) return;

    final items = <Map<String, dynamic>>[];
    for (final c in unsyncedContributions) {
      final goal = await savingsGoalRepo.getByClientId(c.goalId);
      if (goal?.serverId == null) continue; // goal hasn't synced yet, retry later
      items.add({
        'client_generated_id': c.clientGeneratedId,
        'goal_id': goal!.serverId,
        'amount': c.amount,
        'contribution_type': c.contributionType,
        'contribution_date': c.contributionDate.toIso8601String().split('T').first,
      });
    }

    if (items.isEmpty) return;

    final body = {
      'transactions': [],
      'categories': [],
      'payment_methods': [],
      'budgets': [],
      'savings_goals': [],
      'savings_contributions': items,
      'debts': [],
    };

    final response = await dio.post('/sync/batch', data: body);
    final data = response.data as Map<String, dynamic>;

    for (final result in (data['savings_contributions'] as List)) {
      final map = result as Map<String, dynamic>;
      final contribution = map['savings_contribution'] as Map<String, dynamic>;
      await savingsContributionRepo.markSynced(map['client_generated_id'] as String, serverId: contribution['id'] as int?);
    }
  }

  Future<int?> _findPaymentMethodServerId(String clientGeneratedId) async {
    final all = await paymentMethodRepo.getAll(includeArchived: true);
    for (final m in all) {
      if (m.clientGeneratedId == clientGeneratedId) return m.serverId;
    }
    return null;
  }
}