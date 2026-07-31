import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../domain/models/report_status.dart';

class ReportStatusStyle {
  const ReportStatusStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static ReportStatusStyle of(ReportStatus status) {
    return switch (status) {
      ReportStatus.pending => const ReportStatusStyle(
        color: StatusColors.pending,
        icon: Icons.schedule_outlined,
      ),
      ReportStatus.received => const ReportStatusStyle(
        color: StatusColors.received,
        icon: Icons.mark_email_read_outlined,
      ),
      ReportStatus.inProgress => const ReportStatusStyle(
        color: StatusColors.inProgress,
        icon: Icons.construction_outlined,
      ),
      ReportStatus.resolved => const ReportStatusStyle(
        color: StatusColors.resolved,
        icon: Icons.check_circle_outline,
      ),
      ReportStatus.rejected => const ReportStatusStyle(
        color: StatusColors.rejected,
        icon: Icons.block_outlined,
      ),
      ReportStatus.cancelled => const ReportStatusStyle(
        color: StatusColors.cancelled,
        icon: Icons.cancel_outlined,
      ),
      ReportStatus.unknown => const ReportStatusStyle(
        color: StatusColors.unknown,
        icon: Icons.help_outline,
      ),
    };
  }
}

class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({
    required this.status,
    this.compact = false,
    super.key,
  });

  final ReportStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = ReportStatusStyle.of(status);
    return Semantics(
      label: 'Report status ${status.label}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: style.color.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: compact ? 14 : 16, color: style.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: style.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
