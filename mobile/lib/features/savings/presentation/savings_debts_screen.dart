import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../shared/widgets/masked_amount.dart';
import '../../debts/models/debt_model.dart';
import '../../debts/presentation/add_edit_debt_sheet.dart';
import '../../debts/providers/debt_providers.dart';
import '../models/savings_goal_model.dart';
import '../providers/savings_providers.dart';
import 'add_contribution_sheet.dart';
import 'add_edit_goal_sheet.dart';

class SavingsDebtsScreen extends ConsumerStatefulWidget {
  const SavingsDebtsScreen({super.key, this.initialTab = 0});
  final int initialTab; // 0 = Goals, 1 = Debts

  @override
  ConsumerState<SavingsDebtsScreen> createState() => _SavingsDebtsScreenState();
}

class _SavingsDebtsScreenState extends ConsumerState<SavingsDebtsScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Savings & Debts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF3F2F0), borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  Expanded(child: _segment('Goals', 0)),
                  Expanded(child: _segment('Debts', 1)),
                ]),
              ),
            ),
            Expanded(child: _tab == 0 ? const _GoalsTab() : const _DebtsTab()),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 3, offset: const Offset(0, 1))] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
      ),
    );
  }
}

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
      error: (e, _) => Center(child: Text('Could not load goals: $e')),
      data: (goals) => RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () async => ref.invalidate(savingsGoalsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            if (goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: const Column(children: [
                  Text('No goals yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Set a savings target and watch your progress grow.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                ]),
              )
            else
              ...goals.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _GoalCard(goal: g))),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddEditGoalSheet(),
                );
                if (result == true) ref.invalidate(savingsGoalsProvider);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(16)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('New goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final SavingsGoalModel goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = goal.targetAmount > 0 ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    final isReached = goal.savedAmount >= goal.targetAmount;
    final daysRemaining = goal.targetDate == null ? null : goal.targetDate!.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text('${(percent * 100).round()}%',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isReached ? AppColors.success : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(daysRemaining == null ? '' : (daysRemaining >= 0 ? '$daysRemaining days left' : 'Past target date'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(isReached ? 'Goal reached' : 'On track', style: TextStyle(fontSize: 12, color: isReached ? AppColors.success : AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Text('Saved', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('Target', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MaskedAmount('${formatXaf(goal.savedAmount)} XAF', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.success)),
              MaskedAmount('${formatXaf(goal.targetAmount)} XAF', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: AppColors.border, color: isReached ? AppColors.success : AppColors.brand),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: isReached
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('Completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    )
                  : OutlinedButton.icon(
                      onPressed: () async {
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddContributionSheet(goal: goal),
                        );
                        if (result == true) {
                          ref.invalidate(savingsGoalsProvider);
                          ref.invalidate(goalContributionsProvider(goal.clientGeneratedId));
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add funds', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddEditGoalSheet(existing: goal),
                  );
                  if (result == true) ref.invalidate(savingsGoalsProvider);
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _DebtsTab extends ConsumerWidget {
  const _DebtsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);

    return debtsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
      error: (e, _) => Center(child: Text('Could not load debts: $e')),
      data: (debts) {
        final owedToUser = debts.where((d) => d.direction == 'owed_to_user' && !d.isSettled).toList();
        final owedByUser = debts.where((d) => d.direction == 'owed_by_user' && !d.isSettled).toList();
        final totalOwedToUser = owedToUser.fold<int>(0, (sum, d) => sum + d.amount);
        final totalOwedByUser = owedByUser.fold<int>(0, (sum, d) => sum + d.amount);

        return RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async => ref.invalidate(debtsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            children: [
              Row(children: [
                Expanded(child: _summaryCard('Owed to me', totalOwedToUser, AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('I owe', totalOwedByUser, AppColors.error)),
              ]),
              const SizedBox(height: 20),
              if (owedToUser.isNotEmpty) ...[
                const Text('Owed to me', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _debtGroupCard(context, ref, owedToUser),
                const SizedBox(height: 16),
              ],
              if (owedByUser.isNotEmpty) ...[
                const Text('I owe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _debtGroupCard(context, ref, owedByUser),
                const SizedBox(height: 16),
              ],
              if (owedToUser.isEmpty && owedByUser.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: const Text('No open debts. Nice and clear.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                ),
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddEditDebtSheet(),
                  );
                  if (result == true) ref.invalidate(debtsProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(16)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Record a debt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String label, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          MaskedAmount('${formatXaf(amount)} XAF', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _debtGroupCard(BuildContext context, WidgetRef ref, List<DebtModel> debts) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: debts.map<Widget>((d) {
          final isLast = debts.last == d;
          return InkWell(
            onTap: () async {
              if (d.isSettled) return;
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddEditDebtSheet(existing: d),
              );
              if (result == true) ref.invalidate(debtsProvider);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.brand.withOpacity(0.08),
                    child: Text(_initials(d.personName), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.personName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          d.dueDate == null ? (d.note ?? '') : 'due ${DateFormat('d MMM').format(d.dueDate!)}${d.note != null ? ' · ${d.note}' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  MaskedAmount(formatXaf(d.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _settleDebt(context, ref, d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.brand.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
                      child: const Text('Settle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brand)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _settleDebt(BuildContext context, WidgetRef ref, DebtModel debt) async {
    try {
      await ref.read(debtWriteControllerProvider).settleDebt(debt);
      ref.invalidate(debtsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }
}