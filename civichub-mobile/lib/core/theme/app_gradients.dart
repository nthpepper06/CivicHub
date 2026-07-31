import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  static const cityHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navy, AppColors.indigo, AppColors.primaryDark],
  );

  static const surfaceGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surface, AppColors.surfaceAlt],
  );

  static const action = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.cyan],
  );

  static const profile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.violet],
  );
}
