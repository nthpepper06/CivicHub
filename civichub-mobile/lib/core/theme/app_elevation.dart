import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppElevation {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get hover => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.1),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];
}
