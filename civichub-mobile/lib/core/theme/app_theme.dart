import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: const ['Roboto', 'Arial'],
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.surface,
        titleTextStyle: TextStyle(
          color: AppColors.surface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
