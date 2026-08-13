import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/hydration_service.dart';
import 'core_providers.dart';

import '../../features/categories/data/category_api.dart';
import '../../features/categories/data/category_local_repository.dart';
import '../../features/payment_methods/data/payment_method_api.dart';
import '../../features/payment_methods/data/payment_method_local_repository.dart';
import '../../features/transactions/data/transaction_api.dart';
import '../../features/transactions/data/transaction_local_repository.dart';
import '../../features/budgets/data/budget_api.dart';
import '../../features/budgets/data/budget_local_repository.dart';
import '../../features/savings/data/savings_goal_api.dart';
import '../../features/savings/data/savings_goal_local_repository.dart';
import '../../features/savings/data/savings_contribution_local_repository.dart';
import '../../features/debts/data/debt_api.dart';
import '../../features/debts/data/debt_local_repository.dart';

final categoryApiProvider = Provider((ref) => CategoryApi(ref.watch(dioClientProvider).dio));
final categoryLocalRepositoryProvider = Provider((ref) => CategoryLocalRepository(ref.watch(appDatabaseProvider)));

final paymentMethodApiProvider = Provider((ref) => PaymentMethodApi(ref.watch(dioClientProvider).dio));
final paymentMethodLocalRepositoryProvider =
    Provider((ref) => PaymentMethodLocalRepository(ref.watch(appDatabaseProvider)));

final transactionApiProvider = Provider((ref) => TransactionApi(ref.watch(dioClientProvider).dio));
final transactionLocalRepositoryProvider =
    Provider((ref) => TransactionLocalRepository(ref.watch(appDatabaseProvider)));

final budgetApiProvider = Provider((ref) => BudgetApi(ref.watch(dioClientProvider).dio));
final budgetLocalRepositoryProvider = Provider((ref) => BudgetLocalRepository(ref.watch(appDatabaseProvider)));

final savingsGoalApiProvider = Provider((ref) => SavingsGoalApi(ref.watch(dioClientProvider).dio));
final savingsGoalLocalRepositoryProvider =
    Provider((ref) => SavingsGoalLocalRepository(ref.watch(appDatabaseProvider)));
final savingsContributionLocalRepositoryProvider =
    Provider((ref) => SavingsContributionLocalRepository(ref.watch(appDatabaseProvider)));

final debtApiProvider = Provider((ref) => DebtApi(ref.watch(dioClientProvider).dio));
final debtLocalRepositoryProvider = Provider((ref) => DebtLocalRepository(ref.watch(appDatabaseProvider)));

final hydrationServiceProvider = Provider((ref) => HydrationService(
      categoryApi: ref.watch(categoryApiProvider),
      categoryLocalRepository: ref.watch(categoryLocalRepositoryProvider),
      paymentMethodApi: ref.watch(paymentMethodApiProvider),
      paymentMethodLocalRepository: ref.watch(paymentMethodLocalRepositoryProvider),
      transactionApi: ref.watch(transactionApiProvider),
      transactionLocalRepository: ref.watch(transactionLocalRepositoryProvider),
      budgetApi: ref.watch(budgetApiProvider),
      budgetLocalRepository: ref.watch(budgetLocalRepositoryProvider),
      savingsGoalApi: ref.watch(savingsGoalApiProvider),
      savingsGoalLocalRepository: ref.watch(savingsGoalLocalRepositoryProvider),
      savingsContributionLocalRepository: ref.watch(savingsContributionLocalRepositoryProvider),
      debtApi: ref.watch(debtApiProvider),
      debtLocalRepository: ref.watch(debtLocalRepositoryProvider),
    ));