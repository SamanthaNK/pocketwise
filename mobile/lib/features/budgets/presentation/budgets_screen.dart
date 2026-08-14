import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/picker_providers.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../core/utils/error_utils.dart';
import '../../../shared/utils/category_icons.dart';
import '../../../shared/widgets/masked_amount.dart';
import '../models/budget_model.dart';
import '../providers/budget_providers.dart';
import 'add_edit_budget_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Budgets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
          error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load budgets: $e'))),
          data: (budgets) => categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
            error: (e, _) => Center(child: Text('Could not load categories: $e')),
            data: (categories) {
              final categoryById = {for (final c in categories) c.clientGeneratedId: c};
              final isFiftyThirtyTwenty = budgets.isNotEmpty && budgets.first.ruleType == 'fifty_thirty_twenty';

              return RefreshIndicator(
                color: AppColors.brand,
                onRefresh: () async => ref.invalidate(activeBudgetsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    if (budgets.isEmpty)
                      _emptyState(context)
                    else ...[
                      if (isFiftyThirtyTwenty)
                        ..._buildFiftyThirtyTwentyRows(context, ref, budgets)
                      else
                        ..._buildCustomRows(context, ref, budgets, categoryById),
                    ],
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openAddBudgetSheet(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Symbols.add_rounded, size: 18, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('Add budget', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCustomRows(BuildContext context, WidgetRef ref, List<BudgetModel> budgets, Map<String, dynamic> categoryById) {
    return budgets.map((b) {
      final category = categoryById[b.categoryId];
      final percent = b.limitAmount > 0 ? (b.spent / b.limitAmount).clamp(0.0, 1.5) : 0.0;
      final color = percent >= 1.0 ? AppColors.error : (percent >= 0.8 ? AppColors.warning : AppColors.success);

      return GestureDetector(
        onTap: () => _openEditBudgetSheet(context, ref, b),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(iconForCategory(category?.icon), size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(category?.name ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  ]),
                  Row(children: [
                    MaskedAmount(formatXaf(b.spent), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    MaskedAmount(' / ${formatXaf(b.limitAmount)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: percent > 1 ? 1 : percent, minHeight: 4, backgroundColor: AppColors.border, color: color),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  percent >= 1.0
                      ? Text('Running a little higher than usual', style: TextStyle(fontSize: 12, color: color))
                      : (percent >= 0.8
                          ? Text('This category is trending up this month', style: TextStyle(fontSize: 12, color: color))
                          : MaskedAmount('${formatXaf(b.limitAmount - b.spent)} XAF remaining', style: TextStyle(fontSize: 12, color: color))),
                  Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildFiftyThirtyTwentyRows(BuildContext context, WidgetRef ref, List<BudgetModel> budgets) {
    const labels = {'needs': 'Needs', 'wants': 'Wants', 'savings': 'Savings'};
    return budgets.map((b) {
      final percent = b.limitAmount > 0 ? (b.spent / b.limitAmount).clamp(0.0, 1.5) : 0.0;
      final color = percent >= 1.0 ? AppColors.error : (percent >= 0.8 ? AppColors.warning : AppColors.success);

      return GestureDetector(
        onTap: () => _openEditBudgetSheet(context, ref, b),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(labels[b.budgetGroup] ?? b.budgetGroup ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  MaskedAmount('${formatXaf(b.spent)} / ${formatXaf(b.limitAmount)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: percent > 1 ? 1 : percent, minHeight: 4, backgroundColor: AppColors.border, color: color),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: const Column(
        children: [
          Text('Set your first budget.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          SizedBox(height: 6),
          Text('Pick a per-category limit or the simpler 50/30/20 rule to start tracking.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _openAddBudgetSheet(BuildContext context, WidgetRef ref) async {
    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddEditBudgetSheet(),
      );
      if (result == true) ref.invalidate(activeBudgetsProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    }
  }

  Future<void> _openEditBudgetSheet(BuildContext context, WidgetRef ref, BudgetModel budget) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditBudgetSheet(existing: budget),
    );
    if (result == true) ref.invalidate(activeBudgetsProvider);
  }
}