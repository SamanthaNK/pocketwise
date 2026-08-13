import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/fold_clipper.dart';
import '../models/savings_goal_model.dart';
import '../providers/savings_providers.dart';

class AddEditGoalSheet extends ConsumerStatefulWidget {
  const AddEditGoalSheet({super.key, this.existing});
  final SavingsGoalModel? existing;

  @override
  ConsumerState<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends ConsumerState<AddEditGoalSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  DateTime? _targetDate;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _amountController = TextEditingController(text: widget.existing?.targetAmount.toString() ?? '');
    _targetDate = widget.existing?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your goal a name.')));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a target amount greater than zero.')));
      return;
    }

    setState(() => _isSaving = true);
    final controller = ref.read(savingsGoalWriteControllerProvider);
    if (_isEditing) {
      await controller.updateGoal(widget.existing!, name: name, targetAmount: amount, targetDate: _targetDate);
    } else {
      await controller.createGoal(name: name, targetAmount: amount, targetDate: _targetDate);
    }
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
                Text(_isEditing ? 'Edit goal' : 'New goal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                const Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: _nameController, decoration: _decoration(hint: 'e.g. Lagos trip')),
                const SizedBox(height: 16),
                const Text('Target amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: _decoration(suffixText: 'XAF')),
                const SizedBox(height: 16),
                const Text('Target date (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(_targetDate == null ? 'No target date' : DateFormat('d MMM yyyy').format(_targetDate!), style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      if (_targetDate != null)
                        GestureDetector(onTap: () => setState(() => _targetDate = null), child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
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
                              : Text(_isEditing ? 'Save goal' : 'Create goal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
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