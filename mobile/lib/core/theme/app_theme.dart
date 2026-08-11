import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.brand,
          secondary: AppColors.brandSecondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: GoogleFonts.ibmPlexSansTextTheme(),
        dividerColor: AppColors.border,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.brandDark,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
        ),
        textTheme: GoogleFonts.ibmPlexSansTextTheme(ThemeData.dark().textTheme),
      );
}
