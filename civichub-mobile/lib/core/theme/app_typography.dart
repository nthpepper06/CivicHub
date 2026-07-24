import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static const fontFamily = 'Montserrat';

  static TextTheme get textTheme {
    return const TextTheme(
      displaySmall: TextStyle(
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.surface,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }
}
