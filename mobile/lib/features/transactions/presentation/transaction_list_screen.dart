import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/feature_providers.dart';
import '../../../core/providers/picker_providers.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../shared/utils/category_icons.dart';
import '../../../shared/widgets/masked_amount.dart';
import '../models/transaction_model.dart';
import 'edit_transaction_screen.dart';
import 'quick_add_sheet.dart';

final _searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final _filteredTransactionsProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) {
  final query = ref.watch(_searchQueryProvider);
  return ref.watch(transactionLocalRepositoryProvider).getAll(searchQuery: query);
});

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(_filteredTransactionsProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Search descriptions',
                  prefixIcon: const Icon(Symbols.search_rounded, size: 20, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand)),
                ),
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
                error: (e, _) => Center(child: Text('Could not load transactions: $e')),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No transactions yet.', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    );
                  }
                  return categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
                    error: (e, _) => Center(child: Text('Could not load categories: $e')),
                    data: (categories) {
                      final categoryById = {for (final c in categories) c.clientGeneratedId: c};
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final t = transactions[index];
                          final category = categoryById[t.categoryId];
                          final isExpense = t.type == 'expense';
                          return InkWell(
                            onTap: () async {
                              final changed = await Navigator.of(context)
                                  .push<bool>(MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: t)));
                              if (changed == true) ref.invalidate(_filteredTransactionsProvider);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                              child: Row(
                                children: [
                                  Icon(iconForCategory(category?.icon), size: 19, color: AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (t.description == null || t.description!.isEmpty) ? (category?.name ?? 'Uncategorized') : t.description!,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                        ),
                                        Text(
                                          '${category?.name ?? ''} · ${DateFormat('d MMM yyyy').format(t.transactionDate)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MaskedAmount(
                                    '${isExpense ? '−' : '+'} ${formatXaf(t.amount)}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isExpense ? AppColors.textPrimary : AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brand,
        onPressed: () async {
          final added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const QuickAddSheet(),
          );
          if (added == true) ref.invalidate(_filteredTransactionsProvider);
        },
        child: const Icon(Symbols.add_rounded, color: Colors.white),
      ),
    );
  }
}