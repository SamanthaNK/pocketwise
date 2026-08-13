import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/picker_providers.dart';
import '../../../core/utils/amount_utils.dart';
import '../../../shared/widgets/fold_clipper.dart';
import '../../categories/models/category_model.dart';
import '../../payment_methods/models/payment_method_model.dart';
import '../providers/transaction_write_controller.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  String _type = 'expense';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  CategoryModel? _selectedCategory;
  PaymentMethodModel? _selectedPaymentMethod;
  bool _isSaving = false;

  static const _quickAmounts = [500, 1500, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount greater than zero.')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a category.')));
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(transactionWriteControllerProvider).createTransaction(
          categoryId: _selectedCategory!.clientGeneratedId,
          paymentMethodId: _selectedPaymentMethod?.clientGeneratedId,
          type: _type,
          amount: _amount,
          description: _descriptionController.text,
          date: DateTime.now(),
        );
    ref.invalidate(activeCategoriesProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final paymentMethodsAsync = ref.watch(activePaymentMethodsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 16),

                // Expense / Income toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _segmentedToggle(),
                ),

                // Amount entry
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: AppColors.textSecondary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('XAF', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                    ],
                  ),
                ),

                // Quick amount chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: _quickAmounts.map((amt) {
                      final selected = _amount == amt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _amountController.text = amt.toString()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.brand : const Color(0xFFF3F2F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              formatXaf(amt),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textPrimary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Category chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('CATEGORY',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.brand)),
                  error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Could not load categories: $e')),
                  data: (categories) {
                    final filtered = categories.where((c) => c.type == _type).toList();
                    _selectedCategory ??= filtered.isNotEmpty ? filtered.first : null;
                    return SizedBox(
                      height: 76,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: filtered.map((c) {
                          final selected = _selectedCategory?.clientGeneratedId == c.clientGeneratedId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = c),
                              child: Container(
                                width: 68,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.brand.withOpacity(0.08) : const Color(0xFFF3F2F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(iconForCategory(c.icon), size: 20, color: selected ? AppColors.brand : AppColors.textSecondary),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10, color: selected ? AppColors.brand : AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Payment method
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: paymentMethodsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (methods) => GestureDetector(
                      onTap: () => _pickPaymentMethod(methods),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedPaymentMethod?.label ?? 'Payment method (optional)',
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _descriptionController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.edit_note, size: 18, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Save button (the fold)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipPath(
                    clipper: const FoldClipper(),
                    child: Material(
                      color: AppColors.brand,
                      child: InkWell(
                        onTap: _isSaving ? null : _save,
                        child: SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _amount > 0 ? 'Add — ${formatXaf(_amount)} XAF' : 'Add',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentedToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF3F2F0), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          _segment('Expense', 'expense'),
          _segment('Income', 'income'),
        ],
      ),
    );
  }

  Widget _segment(String label, String value) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          _selectedCategory = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 3, offset: const Offset(0, 1))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? (value == 'expense' ? AppColors.error : AppColors.textPrimary) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _pickPaymentMethod(List<PaymentMethodModel> methods) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('None'),
              onTap: () {
                setState(() => _selectedPaymentMethod = null);
                Navigator.pop(context);
              },
            ),
            ...methods.map((m) => ListTile(
                  leading: const Icon(Icons.payments, color: AppColors.textSecondary),
                  title: Text(m.label),
                  onTap: () {
                    setState(() => _selectedPaymentMethod = m);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

IconData iconForCategory(String? symbolName) {
  switch (symbolName) {
    case 'restaurant':
      return Icons.restaurant;
    case 'directions_bus':
      return Icons.directions_bus;
    case 'bolt':
      return Icons.bolt;
    case 'home':
      return Icons.home;
    case 'sim_card':
      return Icons.sim_card;
    case 'medical_services':
      return Icons.medical_services;
    case 'school':
      return Icons.school;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'celebration':
      return Icons.celebration;
    case 'savings':
      return Icons.savings;
    case 'payments':
      return Icons.payments;
    case 'storefront':
      return Icons.storefront;
    case 'redeem':
      return Icons.redeem;
    case 'account_balance_wallet':
      return Icons.account_balance_wallet;
    default:
      return Icons.category;
  }
}