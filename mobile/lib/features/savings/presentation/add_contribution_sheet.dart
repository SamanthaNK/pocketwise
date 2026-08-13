import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/fold_clipper.dart';
import '../models/savings_goal_model.dart';
import '../providers/savings_providers.dart';

class AddContributionSheet extends ConsumerStatefulWidget {
  const AddContributionSheet({super.key, required this.goal});
  final SavingsGoalModel goal;

  @override
  ConsumerState<AddContributionSheet> createState() => _AddContributionSheetState();
}

class _AddContributionSheetState extends ConsumerState<AddContributionSheet> {
  final _amountController = TextEditingController();
  String _type = 'deposit';
  bool _isSaving = false;

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
    final error = await ref.read(savingsGoalWriteControllerProvider).addContribution(
          goalClientId: widget.goal.clientGeneratedId,
          amount: amount,
          contributionType: _type,
          date: DateTime.now(),
        );

    if (!mounted) return;
    if (error != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 16),
                Text('Add to "${widget.goal.name}"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F2F0), borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    Expanded(child: _segment('Deposit', 'deposit')),
                    Expanded(child: _segment('Withdraw', 'withdrawal')),
                  ]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
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
                              : Text(_type == 'deposit' ? 'Add funds' : 'Withdraw', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
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
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
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
}