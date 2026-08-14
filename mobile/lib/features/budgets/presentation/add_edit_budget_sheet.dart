import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/picker_providers.dart';
import '../../../core/utils/error_utils.dart';
import '../../../shared/utils/category_icons.dart';
import '../../../shared/widgets/fold_clipper.dart';
import '../models/budget_model.dart';
import '../providers/budget_providers.dart';

class AddEditBudgetSheet extends ConsumerStatefulWidget {
  const AddEditBudgetSheet({super.key, this.existing});
  final BudgetModel? existing;

  @override
  ConsumerState<AddEditBudgetSheet> createState() => _AddEditBudgetSheetState();
}

class _AddEditBudgetSheetState extends ConsumerState<AddEditBudgetSheet> {
  late String _mode;
  String? _selectedCategoryId;
  final _amountController = TextEditingController();
  String _period = 'monthly';
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _mode = widget.existing?.ruleType ?? 'custom';
    _period = widget.existing?.periodType ?? 'monthly';
    _selectedCategoryId = widget.existing?.categoryId;
    _amountController.text = _isEditing
        ? (_mode == 'custom' ? widget.existing!.limitAmount.toString() : (widget.existing!.declaredIncome ?? 0).toString())
        : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount greater than zero.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final controller = ref.read(budgetWriteControllerProvider);

      if (_isEditing) {
        await controller.update(widget.existing!.id, limitAmount: amount, periodType: _period);
      } else if (_mode == 'custom') {
        if (_selectedCategoryId == null) {
          throw Exception('Pick a category.');
        }
        final categories = await ref.read(activeCategoriesProvider.future);
        final category = categories.firstWhere((c) => c.clientGeneratedId == _selectedCategoryId);
        if (category.serverId == null) throw Exception('This category has not synced yet. Try again once online.');
        await controller.createCustom(categoryServerId: category.serverId!, limitAmount: amount, periodType: _period);
      } else {
        await controller.createFiftyThirtyTwenty(declaredIncome: amount);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
                ),
                const SizedBox(height: 16),
                Text(_isEditing ? 'Edit budget' : 'Add budget', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                if (!_isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(999)),
                    child: Row(children: [
                      Expanded(child: _modeSegment('By category', 'custom')),
                      Expanded(child: _modeSegment('50/30/20 Rule', 'fifty_thirty_twenty')),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_mode == 'custom' && !_isEditing) ...[
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    loading: () => const CircularProgressIndicator(color: AppColors.brand),
                    error: (e, _) => Text('Could not load categories: $e'),
                    data: (categories) {
                      final expenseCategories = categories.where((c) => c.type == 'expense').toList();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: expenseCategories.map((c) {
                          final selected = c.clientGeneratedId == _selectedCategoryId;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategoryId = c.clientGeneratedId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.brand.withValues(alpha: 0.08) : AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(iconForCategory(c.icon), size: 16, color: selected ? AppColors.brand : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(c.name, style: TextStyle(fontSize: 13, color: selected ? AppColors.brand : AppColors.textPrimary)),
                              ]),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  _isEditing
                      ? (_mode == 'custom' ? 'Budget amount' : 'Group limit')
                      : (_mode == 'custom' ? 'Budget amount' : 'Monthly income'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    suffixText: 'XAF',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand)),
                  ),
                ),

                if (_mode == 'custom') ...[
                  const SizedBox(height: 16),
                  const Text('Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(999)),
                    child: Row(children: [
                      Expanded(child: _periodSegment('Weekly', 'weekly')),
                      Expanded(child: _periodSegment('Monthly', 'monthly')),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),
                ClipPath(
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
                              : Text(_isEditing ? 'Save budget' : 'Create budget',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeSegment(String label, String value) {
    final selected = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 3, offset: const Offset(0, 1))] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
      ),
    );
  }

  Widget _periodSegment(String label, String value) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 3, offset: const Offset(0, 1))] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
      ),
    );
  }
}