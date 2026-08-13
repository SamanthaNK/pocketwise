import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/analytics_local_repository.dart';

final analyticsLocalRepositoryProvider = Provider((ref) => AnalyticsLocalRepository(ref.watch(appDatabaseProvider)));

class AnalyticsData {
  AnalyticsData({required this.totalExpense, required this.previousMonthExpense, required this.breakdown, required this.trend});
  final int totalExpense;
  final int previousMonthExpense;
  final List<CategoryBreakdownRow> breakdown;
  final List<TrendRow> trend;
}

final analyticsDataProvider = FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final repo = ref.watch(analyticsLocalRepositoryProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  final prevMonthDate = DateTime(now.year, now.month - 1, 1);
  final prevMonthStart = DateTime(prevMonthDate.year, prevMonthDate.month, 1);
  final prevMonthEnd = DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0);

  final totals = await repo.totalsForRange(monthStart, monthEnd);
  final prevTotals = await repo.totalsForRange(prevMonthStart, prevMonthEnd);
  final breakdown = await repo.expenseBreakdownByCategory(monthStart, monthEnd);
  final trend = await repo.monthlyTrend(6);

  return AnalyticsData(totalExpense: totals.expense, previousMonthExpense: prevTotals.expense, breakdown: breakdown, trend: trend);
});