import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/fold_clipper.dart';
import '../models/debt_model.dart';
import '../providers/debt_providers.dart';

class AddEditDebtSheet extends ConsumerStatefulWidget {
  const AddEditDebtSheet({super.key, this.existing});
  final DebtModel? existing;

  @override
  ConsumerState<AddEditDebtSheet> createState() => _AddEditDebtSheetState();
}

class _AddEditDebtSheetState extends ConsumerState<AddEditDebtSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _direction;
  DateTime? _dueDate;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.personName ?? '');
    _amountController = TextEditingController(text: widget.existing?.amount.toString() ?? '');
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
    _direction = widget.existing?.direction ?? 'owed_to_user';
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter the person's name.")));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount greater than zero.')));
      return;
    }

    setState(() => _isSaving = true);
    final controller = ref.read(debtWriteControllerProvider);
    if (_isEditing) {
      await controller.updateDebt(widget.existing!,
          personName: name, amount: amount, direction: _direction, dueDate: _dueDate, note: _noteController.text);
    } else {
      await controller.createDebt(personName: name, amount: amount, direction: _direction, dueDate: _dueDate, note: _noteController.text);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    await ref.read(debtWriteControllerProvider).deleteDebt(widget.existing!.clientGeneratedId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isEditing ? 'Edit debt' : 'Record a debt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    if (_isEditing)
                      GestureDetector(onTap: _isSaving ? null : _delete, child: const Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error))),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F2F0), borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    Expanded(child: _segment('Owed to me', 'owed_to_user')),
                    Expanded(child: _segment('I owe', 'owed_by_user')),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Person', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: _nameController, decoration: _decoration(hint: "Person's name")),
                const SizedBox(height: 16),
                const Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: _decoration(suffixText: 'XAF')),
                const SizedBox(height: 16),
                const Text('Due date (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(_dueDate == null ? 'No due date' : DateFormat('d MMM yyyy').format(_dueDate!), style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(onTap: () => setState(() => _dueDate = null), child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Note (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: _noteController, decoration: _decoration(hint: 'e.g. Phone loan')),
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
                              : Text(_isEditing ? 'Save debt' : 'Record debt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
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

  Widget _segment(String label, String value) {
    final selected = _direction == value;
    return GestureDetector(
      onTap: () => setState(() => _direction = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 3, offset: const Offset(0, 1))] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
      ),
    );
  }

  InputDecoration _decoration({String? hint, String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand)),
    );
  }
}