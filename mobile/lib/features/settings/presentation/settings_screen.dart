import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/privacy_mode_provider.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/error_utils.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isPrivate = ref.watch(privacyModeProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            userAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.brand))),
              error: (e, _) => Text('Could not load your profile: $e', style: const TextStyle(color: AppColors.textSecondary)),
              data: (user) => _profileCard(context, ref, user),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Privacy'),
            _card([
              _toggleRow(icon: Icons.visibility_off, label: 'Privacy Mode', value: isPrivate, onChanged: (_) => ref.read(privacyModeProvider.notifier).toggle()),
            ]),
            const SizedBox(height: 16),
            _sectionLabel('Sync'),
            _card([
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sync, color: AppColors.textSecondary),
                title: const Text('Sync now', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                subtitle: Text(_syncStatusLabel(syncStatus), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: syncStatus == SyncStatus.syncing
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand))
                    : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () => ref.read(syncManagerProvider).syncNow(),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionLabel('Account'),
            _card([
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password, color: AppColors.textSecondary),
                title: const Text('Change password', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () => _openChangePassword(context, ref),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF3F2F0), borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.offline_bolt, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "PocketWise works entirely offline. Your data stays on your device — everything syncs when you're back online.",
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _logout(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _syncStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.error:
        return "Couldn't sync — we'll try again automatically.";
      case SyncStatus.idle:
        return 'Everything is synced.';
    }
  }

  Widget _profileCard(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.brand,
            child: Text(_initials(user['name'] as String? ?? '?'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] as String? ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(user['email'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('Currency: ${user['currency_preference'] ?? 'XAF'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary), onPressed: () => _openEditProfile(context, ref, user['name'] as String? ?? '')),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.textSecondary)),
      );

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: children),
    );
  }

  Widget _toggleRow({required IconData icon, required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      trailing: Switch(value: value, activeColor: AppColors.brand, onChanged: onChanged),
    );
  }

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Your name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;

    try {
      await ref.read(settingsApiProvider).updateProfile(newName);
      ref.invalidate(currentUserProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    }
  }

  Future<void> _openChangePassword(BuildContext context, WidgetRef ref) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(hintText: 'Current password')),
            const SizedBox(height: 8),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(hintText: 'New password (min. 8 characters)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (newController.text.length < 8) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 8 characters.')));
      return;
    }

    try {
      await ref.read(settingsApiProvider).changePassword(currentPassword: currentController.text, newPassword: newController.text);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in anytime — your data stays safe on the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authRepositoryProvider).logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }
}