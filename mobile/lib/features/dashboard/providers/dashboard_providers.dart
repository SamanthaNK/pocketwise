import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/feature_providers.dart';
import '../../categories/models/category_model.dart';
import '../../transactions/models/transaction_model.dart';

class DashboardData {
  DashboardData({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.recentTransactions,
    required this.categoryById,
  });

  final int balance;
  final int monthIncome;
  final int monthExpense;
  final List<TransactionModel> recentTransactions;
  final Map<String, CategoryModel> categoryById;
}

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final txRepo = ref.watch(transactionLocalRepositoryProvider);
  final catRepo = ref.watch(categoryLocalRepositoryProvider);

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  final totals = await txRepo.getTotalsForRange(monthStart, monthEnd);
  final balance = await txRepo.getAllTimeBalance();
  final recent = await txRepo.getRecent(limit: 10);
  final categories = await catRepo.getAll(includeArchived: true);
  final categoryById = {for (final c in categories) c.clientGeneratedId: c};

  return DashboardData(
    balance: balance,
    monthIncome: totals.income,
    monthExpense: totals.expense,
    recentTransactions: recent,
    categoryById: categoryById,
  );
});