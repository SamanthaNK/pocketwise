import '../../features/budgets/data/budget_api.dart';
import '../../features/budgets/data/budget_local_repository.dart';
import '../../features/categories/data/category_api.dart';
import '../../features/categories/data/category_local_repository.dart';
import '../../features/debts/data/debt_api.dart';
import '../../features/debts/data/debt_local_repository.dart';
import '../../features/payment_methods/data/payment_method_api.dart';
import '../../features/payment_methods/data/payment_method_local_repository.dart';
import '../../features/savings/data/savings_contribution_local_repository.dart';
import '../../features/savings/data/savings_goal_api.dart';
import '../../features/savings/data/savings_goal_local_repository.dart';
import '../../features/transactions/data/transaction_api.dart';
import '../../features/transactions/data/transaction_local_repository.dart';

class HydrationService {
  HydrationService({
    required this.categoryApi,
    required this.categoryLocalRepository,
    required this.paymentMethodApi,
    required this.paymentMethodLocalRepository,
    required this.transactionApi,
    required this.transactionLocalRepository,
    required this.budgetApi,
    required this.budgetLocalRepository,
    required this.savingsGoalApi,
    required this.savingsGoalLocalRepository,
    required this.savingsContributionLocalRepository,
    required this.debtApi,
    required this.debtLocalRepository,
  });

  final CategoryApi categoryApi;
  final CategoryLocalRepository categoryLocalRepository;
  final PaymentMethodApi paymentMethodApi;
  final PaymentMethodLocalRepository paymentMethodLocalRepository;
  final TransactionApi transactionApi;
  final TransactionLocalRepository transactionLocalRepository;
  final BudgetApi budgetApi;
  final BudgetLocalRepository budgetLocalRepository;
  final SavingsGoalApi savingsGoalApi;
  final SavingsGoalLocalRepository savingsGoalLocalRepository;
  final SavingsContributionLocalRepository savingsContributionLocalRepository;
  final DebtApi debtApi;
  final DebtLocalRepository debtLocalRepository;

  Future<void> hydrateAll() async {
    final categories = await categoryApi.fetchAll();
    await categoryLocalRepository.upsertAll(categories);

    final paymentMethods = await paymentMethodApi.fetchAll();
    await paymentMethodLocalRepository.upsertAll(paymentMethods);

    final categoryIdByServerId = {for (final c in categories) c.serverId: c.clientGeneratedId};
    final paymentMethodIdByServerId = {for (final p in paymentMethods) p.serverId: p.clientGeneratedId};

    final transactions = await transactionApi.fetchAll();
    final resolvedTransactions = transactions
        .map((t) => t.copyWithLocalIds(
              categoryIdByServerId[t.categoryServerId] ?? '',
              paymentMethodIdByServerId[t.paymentMethodServerId],
            ))
        .toList();
    await transactionLocalRepository.upsertAll(resolvedTransactions);

    final budgets = await budgetApi.fetchActive();
    final resolvedBudgets = budgets
        .map((b) => b.copyWithLocalCategoryId(
              b.categoryServerId == null ? null : categoryIdByServerId[b.categoryServerId],
            ))
        .toList();
    await budgetLocalRepository.upsertAll(resolvedBudgets);

    final goals = await savingsGoalApi.fetchAll();
    await savingsGoalLocalRepository.upsertAll(goals);

    for (final goal in goals) {
      if (goal.serverId == null) continue;
      final contributions = await savingsGoalApi.fetchContributions(goal.serverId!);
      final resolved = contributions.map((c) => c.copyWithGoalId(goal.clientGeneratedId)).toList();
      await savingsContributionLocalRepository.upsertAll(resolved);
    }

    final debts = await debtApi.fetchAll();
    await debtLocalRepository.upsertAll(debts);
  }
}