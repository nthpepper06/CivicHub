import 'package:flutter/material.dart';

import 'app_colors.dart';

class StatusColors {
  static const pending = AppColors.warning;
  static const received = AppColors.primary;
  static const inProgress = AppColors.violet;
  static const resolved = AppColors.success;
  static const rejected = AppColors.danger;
  static const cancelled = AppColors.muted;
  static const unknown = AppColors.muted;
}

Color statusColorFor(String value) {
  return switch (value) {
    'PENDING' => StatusColors.pending,
    'RECEIVED' => StatusColors.received,
    'IN_PROGRESS' => StatusColors.inProgress,
    'RESOLVED' => StatusColors.resolved,
    'REJECTED' => StatusColors.rejected,
    'CANCELLED' => StatusColors.cancelled,
    _ => StatusColors.unknown,
  };
}

class CategoryColors {
  static Color colorFor(String? value) {
    final text = (value ?? '').toLowerCase();
    if (text.contains('road') || text.contains('traffic')) {
      return AppColors.warning;
    }
    if (text.contains('light') || text.contains('electric')) {
      return AppColors.violet;
    }
    if (text.contains('water') || text.contains('drain')) {
      return AppColors.cyan;
    }
    if (text.contains('tree') ||
        text.contains('green') ||
        text.contains('park')) {
      return AppColors.success;
    }
    if (text.contains('trash') || text.contains('waste')) {
      return AppColors.danger;
    }
    return AppColors.primary;
  }

  static IconData iconFor(String? value) {
    final text = (value ?? '').toLowerCase();
    if (text.contains('road') || text.contains('traffic')) {
      return Icons.traffic_outlined;
    }
    if (text.contains('light') || text.contains('electric')) {
      return Icons.lightbulb_outline;
    }
    if (text.contains('water') || text.contains('drain')) {
      return Icons.water_drop_outlined;
    }
    if (text.contains('tree') ||
        text.contains('green') ||
        text.contains('park')) {
      return Icons.park_outlined;
    }
    if (text.contains('trash') || text.contains('waste')) {
      return Icons.delete_outline;
    }
    return Icons.assignment_outlined;
  }
}

class DepartmentColors {
  static Color colorFor(String? value) {
    final seed = (value ?? 'unassigned').codeUnits.fold<int>(
      0,
      (sum, unit) => sum + unit,
    );
    const palette = [
      AppColors.primary,
      AppColors.cyan,
      AppColors.violet,
      AppColors.success,
      AppColors.warning,
      AppColors.indigo,
    ];
    return palette[seed % palette.length];
  }
}

class NotificationColors {
  static Color colorFor(String apiValue) {
    return switch (apiValue) {
      'REPORT_ASSIGNED' => AppColors.violet,
      'REPORT_STATUS_CHANGED' => AppColors.primary,
      _ => AppColors.cyan,
    };
  }

  static IconData iconFor(String apiValue) {
    return switch (apiValue) {
      'REPORT_ASSIGNED' => Icons.apartment_outlined,
      'REPORT_STATUS_CHANGED' => Icons.change_circle_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
