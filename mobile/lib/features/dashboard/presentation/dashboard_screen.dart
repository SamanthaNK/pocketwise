import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../shared/widgets/fold_clipper.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../transactions/presentation/quick_add_sheet.dart';
import '../../transactions/presentation/transaction_list_screen.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brand)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your dashboard: $error',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (data) => RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async => ref.invalidate(dashboardDataProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _balanceCard(data),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _quickLinkTile(
                        context,
                        icon: Icons.donut_small,
                        label: 'Budgets',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const BudgetsScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TransactionListScreen())),
                      child: const Text('See all',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.brand)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.recentTransactions.isEmpty)
                  _emptyState()
                else
                  ...data.recentTransactions
                      .map((t) => _transactionRow(t, data)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ClipPath(
        clipper: const FoldClipper(notchSize: 14, cornerRadius: 999),
        child: FloatingActionButton(
          backgroundColor: AppColors.brand,
          onPressed: () async {
            final added = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const QuickAddSheet(),
            );
            if (added == true) ref.invalidate(dashboardDataProvider);
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _quickLinkTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total balance',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatXaf(data.balance),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              const Text('XAF',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.arrow_upward, size: 13, color: AppColors.success),
                SizedBox(width: 6),
                Text('Income · this month',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
              Text('+ ${formatXaf(data.monthIncome)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.arrow_downward, size: 13, color: AppColors.error),
                SizedBox(width: 6),
                Text('Expenses · this month',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
              Text('− ${formatXaf(data.monthExpense)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transactionRow(dynamic t, DashboardData data) {
    final category = data.categoryById[t.categoryId];
    final isExpense = t.type == 'expense';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Icon(iconForCategory(category?.icon),
              size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (t.description == null || t.description.toString().isEmpty)
                      ? (category?.name ?? 'Uncategorized')
                      : t.description,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                ),
                Text(category?.name ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isExpense ? '−' : '+'} ${formatXaf(t.amount as int)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isExpense ? AppColors.textPrimary : AppColors.success,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Text('Your financial story starts here.',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          SizedBox(height: 6),
          Text('Add your first transaction to begin tracking your spending.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}