import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/picker_providers.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_write_controller.dart';
import 'quick_add_sheet.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({super.key, required this.transaction});
  final TransactionModel transaction;

  @override
  ConsumerState<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _type;
  late DateTime _date;
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _descriptionController = TextEditingController(text: widget.transaction.description ?? '');
    _type = widget.transaction.type;
    _date = widget.transaction.transactionDate;
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedPaymentMethodId = widget.transaction.paymentMethodId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount greater than zero.')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a category.')));
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(transactionWriteControllerProvider).updateTransaction(
          widget.transaction,
          categoryId: _selectedCategoryId!,
          type: _type,
          paymentMethodId: _selectedPaymentMethodId,
          amount: amount,
          description: _descriptionController.text,
          date: _date,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: const Text('This removes it from your device. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(transactionWriteControllerProvider).deleteTransaction(widget.transaction.clientGeneratedId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final paymentMethodsAsync = ref.watch(activePaymentMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Edit transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _isSaving ? null : _delete, icon: const Icon(Icons.delete_outline, color: AppColors.error)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(child: _typeChip('Expense', 'expense')),
                const SizedBox(width: 8),
                Expanded(child: _typeChip('Income', 'income')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              decoration: _fieldDecoration(suffixText: 'XAF'),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(color: AppColors.brand),
              error: (e, _) => Text('Could not load categories: $e'),
              data: (categories) {
                final filtered = categories.where((c) => c.type == _type).toList();
                if (_selectedCategoryId == null || filtered.every((c) => c.clientGeneratedId != _selectedCategoryId)) {
                  _selectedCategoryId = filtered.isNotEmpty ? filtered.first.clientGeneratedId : null;
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filtered.map((c) {
                    final selected = c.clientGeneratedId == _selectedCategoryId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryId = c.clientGeneratedId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.brand.withOpacity(0.08) : const Color(0xFFF3F2F0),
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
            const Text('Payment method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            paymentMethodsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (methods) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _paymentChip('None', null, methods),
                  ...methods.map((m) => _paymentChip(m.label, m.clientGeneratedId, methods)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(DateFormat('d MMM yyyy').format(_date), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(controller: _descriptionController, decoration: _fieldDecoration()),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surface,
          border: Border.all(color: selected ? AppColors.brand : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _paymentChip(String label, String? id, List methods) {
    final selected = _selectedPaymentMethodId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethodId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withOpacity(0.08) : const Color(0xFFF3F2F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? AppColors.brand : AppColors.textPrimary)),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? suffixText}) {
    return InputDecoration(
      suffixText: suffixText,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand)),
    );
  }
}