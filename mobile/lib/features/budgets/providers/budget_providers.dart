import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/feature_providers.dart';
import '../../../core/providers/picker_providers.dart';
import '../models/budget_model.dart';

final activeBudgetsProvider = FutureProvider.autoDispose<List<BudgetModel>>((ref) {
  return ref.watch(budgetLocalRepositoryProvider).getActive();
});

class BudgetWriteController {
  BudgetWriteController(this._ref);
  final Ref _ref;

  Future<void> createCustom({required int categoryServerId, required int limitAmount, required String periodType}) async {
    final api = _ref.read(budgetApiProvider);
    await api.create({
      'rule_type': 'custom',
      'category_id': categoryServerId,
      'limit_amount': limitAmount,
      'period_type': periodType,
    });
    await _refreshLocal();
  }

  Future<void> createFiftyThirtyTwenty({required int declaredIncome}) async {
    final api = _ref.read(budgetApiProvider);
    await api.create({
      'rule_type': 'fifty_thirty_twenty',
      'declared_income': declaredIncome,
    });
    await _refreshLocal();
  }

  Future<void> update(int budgetId, {int? limitAmount, String? periodType}) async {
    final api = _ref.read(budgetApiProvider);
    final body = <String, dynamic>{};
    if (limitAmount != null) body['limit_amount'] = limitAmount;
    if (periodType != null) body['period_type'] = periodType;
    await api.update(budgetId, body);
    await _refreshLocal();
  }

  Future<void> delete(int budgetId) async {
    await _ref.read(budgetLocalRepositoryProvider).softDelete(budgetId);
    _ref.invalidate(activeBudgetsProvider);
  }

  Future<void> _refreshLocal() async {
    final api = _ref.read(budgetApiProvider);
    final repo = _ref.read(budgetLocalRepositoryProvider);
    final categories = await _ref.read(activeCategoriesProvider.future);
    final categoryIdByServerId = {for (final c in categories) c.serverId: c.clientGeneratedId};

    final budgets = await api.fetchActive();
    final resolved = budgets
        .map((b) => b.copyWithLocalCategoryId(b.categoryServerId == null ? null : categoryIdByServerId[b.categoryServerId]))
        .toList();
    await repo.upsertAll(resolved);
    _ref.invalidate(activeBudgetsProvider);
  }
}

final budgetWriteControllerProvider = Provider((ref) => BudgetWriteController(ref));