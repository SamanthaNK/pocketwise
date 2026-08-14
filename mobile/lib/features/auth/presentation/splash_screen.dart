import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/app_shell.dart';
import '../providers/auth_providers.dart';
import 'login_screen.dart';

const _minSplashDuration = Duration(milliseconds: 1100);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  final _startedAt = DateTime.now();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final authRepository = ref.read(authRepositoryProvider);
    final hasSession = await authRepository.hasActiveSession();

    if (!hasSession) {
      await _waitForMinimumDuration();
      _goTo(const LoginScreen());
      return;
    }

    // Hydration is best-effort background work; a valid session is enough to
    // enter the app and read whatever is already cached locally.
    unawaited(authRepository.hydrateInBackground());
    await _waitForMinimumDuration();
    _goTo(const AppShell());
  }

  Future<void> _waitForMinimumDuration() async {
    final remaining = _minSplashDuration - DateTime.now().difference(_startedAt);
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulseController.value);
            return Opacity(
              opacity: 0.85 + (0.15 * t),
              child: Transform.scale(scale: 0.95 + (0.05 * t), child: child),
            );
          },
          child: Image.asset('assets/branding/logo_full.png', width: 220),
        ),
      ),
    );
  }
}
