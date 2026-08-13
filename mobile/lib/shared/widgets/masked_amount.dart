import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/privacy_mode_provider.dart';

class MaskedAmount extends ConsumerWidget {
  const MaskedAmount(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider);
    final tabularStyle = (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Text(isPrivate ? '••••••' : text, style: tabularStyle);
  }
}