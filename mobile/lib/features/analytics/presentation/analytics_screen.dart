import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../shared/widgets/masked_amount.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
          error: (e, _) => Center(child: Text('Could not load analytics: $e')),
          data: (data) {
            final change = data.previousMonthExpense > 0
                ? ((data.totalExpense - data.previousMonthExpense) / data.previousMonthExpense * 100).round()
                : 0;
            final isUp = change >= 0;
            final maxTrend = data.trend.map((t) => t.expense).fold<int>(1, (a, b) => a > b ? a : b);

            return RefreshIndicator(
              color: AppColors.brand,
              onRefresh: () async => ref.invalidate(analyticsDataProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This month · Spending', style: TextStyle(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 4),
                        MaskedAmount(formatXaf(data.totalExpense),
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -1)),
                        const SizedBox(height: 12),
                        if (data.previousMonthExpense > 0)
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                              child: Row(children: [
                                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('${change.abs()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Text('vs ${formatXaf(data.previousMonthExpense)} XAF last month', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Where is your money going?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  if (data.breakdown.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: const Text('No expenses recorded this month yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: data.breakdown.map((row) {
                          final percent = data.totalExpense > 0 ? row.amount / data.totalExpense : 0.0;
                          final isLast = data.breakdown.last == row;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(row.name, style: const TextStyle(fontSize: 14)),
                                    Row(children: [
                                      MaskedAmount(formatXaf(row.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Text('${(percent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ]),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: AppColors.border, color: AppColors.brand),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text('6-month trend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 90,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: data.trend.map((t) {
                              final isCurrent = data.trend.last == t;
                              final height = maxTrend > 0 ? (t.expense / maxTrend) * 80 : 0.0;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    height: height < 4 ? 4 : height,
                                    decoration: BoxDecoration(
                                      color: isCurrent ? AppColors.brand : AppColors.brand.withOpacity(0.16),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: data.trend
                              .map((t) => Expanded(
                                    child: Text(t.label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 10, color: data.trend.last == t ? AppColors.brand : AppColors.textSecondary)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}