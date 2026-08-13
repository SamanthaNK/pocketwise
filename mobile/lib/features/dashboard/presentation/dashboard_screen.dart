import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/privacy_mode_provider.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../shared/widgets/masked_amount.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../budgets/presentation/budgets_screen.dart';
import '../../savings/presentation/savings_debts_screen.dart';
import '../../transactions/presentation/quick_add_sheet.dart';
import '../../transactions/presentation/transaction_list_screen.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final isPrivate = ref.watch(privacyModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(isPrivate ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                    onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: dashboardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
                error: (error, _) => Center(
                  child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load your dashboard: $error', textAlign: TextAlign.center)),
                ),
                data: (data) => RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: () async => ref.invalidate(dashboardDataProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      _balanceCard(data),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _quickLinkTile(icon: Icons.donut_small, label: 'Budgets', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetsScreen())))),
                        const SizedBox(width: 8),
                        Expanded(child: _quickLinkTile(icon: Icons.savings, label: 'Savings', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavingsDebtsScreen())))),
                        const SizedBox(width: 8),
                        Expanded(child: _quickLinkTile(icon: Icons.handshake, label: 'Debts', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavingsDebtsScreen(initialTab: 1))))),
                        const SizedBox(width: 8),
                        Expanded(child: _quickLinkTile(icon: Icons.bar_chart, label: 'Analytics', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())))),
                      ]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionListScreen())),
                            child: const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brand)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (data.recentTransactions.isEmpty) _emptyState() else ...data.recentTransactions.map((t) => _transactionRow(t, data)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total balance', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            MaskedAmount(formatXaf(data.balance), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            const Text('XAF', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: const [Icon(Icons.arrow_upward, size: 13, color: AppColors.success), SizedBox(width: 6), Text('Income · this month', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]),
            MaskedAmount('+ ${formatXaf(data.monthIncome)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: const [Icon(Icons.arrow_downward, size: 13, color: AppColors.error), SizedBox(width: 6), Text('Expenses · this month', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]),
            MaskedAmount('− ${formatXaf(data.monthExpense)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
        ],
      ),
    );
  }

  Widget _quickLinkTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _transactionRow(dynamic t, DashboardData data) {
    final category = data.categoryById[t.categoryId];
    final isExpense = t.type == 'expense';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Icon(iconForCategory(category?.icon), size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((t.description == null || t.description.toString().isEmpty) ? (category?.name ?? 'Uncategorized') : t.description,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text(category?.name ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        MaskedAmount('${isExpense ? '−' : '+'} ${formatXaf(t.amount as int)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isExpense ? AppColors.textPrimary : AppColors.success)),
      ]),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: const Column(children: [
        Text('Your financial story starts here.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
        SizedBox(height: 6),
        Text('Add your first transaction to begin tracking your spending.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}