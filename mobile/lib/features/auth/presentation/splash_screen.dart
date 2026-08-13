import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../providers/auth_providers.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final authRepository = ref.read(authRepositoryProvider);
    final hasSession = await authRepository.hasActiveSession();

    if (!hasSession) {
      _goTo(const LoginScreen());
      return;
    }

    // Hydration is best-effort background work; a valid session is enough to
    // enter the app and read whatever is already cached locally.
    unawaited(authRepository.hydrateInBackground());
    _goTo(const DashboardScreen());
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'PocketWise',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.brand),
        ),
      ),
    );
  }
}