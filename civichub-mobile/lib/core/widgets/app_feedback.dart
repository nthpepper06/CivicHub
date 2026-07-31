import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppFeedbackType { success, error, info, warning }

class AppFeedback {
  const AppFeedback._();

  static void show(
    BuildContext context, {
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _background(type),
          content: Row(
            children: [
              Icon(_icon(type), color: AppColors.surface, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static Color _background(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => AppColors.success,
      AppFeedbackType.error => AppColors.danger,
      AppFeedbackType.warning => AppColors.warning,
      AppFeedbackType.info => AppColors.primary,
    };
  }

  static IconData _icon(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => Icons.check_circle_outline,
      AppFeedbackType.error => Icons.error_outline,
      AppFeedbackType.warning => Icons.warning_amber_outlined,
      AppFeedbackType.info => Icons.info_outline,
    };
  }
}
