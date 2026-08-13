import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/savings/presentation/savings_debts_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/quick_add_sheet.dart';
import '../../shared/widgets/fold_clipper.dart';
import '../constants/app_colors.dart';
import '../sync/sync_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    BudgetsScreen(),
    SavingsDebtsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ref.read(connectivitySyncTriggerProvider);
  }

  Future<void> _openQuickAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddSheet(),
    );
    if (added == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: ClipPath(
        clipper: const FoldClipper(notchSize: 14, cornerRadius: 999),
        child: FloatingActionButton(backgroundColor: AppColors.brand, onPressed: _openQuickAdd, child: const Icon(Icons.add, color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home, label: 'Home', index: 0),
              _navItem(icon: Icons.donut_small, label: 'Budgets', index: 1),
              const SizedBox(width: 40),
              _navItem(icon: Icons.savings, label: 'Savings', index: 2),
              _navItem(icon: Icons.settings, label: 'Settings', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final selected = _index == index;
    return InkWell(
      onTap: () => setState(() => _index = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: selected ? AppColors.brand : AppColors.textSecondary),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: selected ? AppColors.brand : AppColors.textSecondary)),
        ],
      ),
    );
  }
}