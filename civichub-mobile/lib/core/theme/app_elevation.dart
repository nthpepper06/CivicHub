import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppElevation {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get hover => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.12),
      blurRadius: 34,
      offset: const Offset(0, 16),
    ),
  ];
}
