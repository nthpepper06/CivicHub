import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../../reports/presentation/widgets/report_status_chip.dart';
import 'staff_meta_chip.dart';

class StaffReportCard extends StatelessWidget {
  const StaffReportCard({
    required this.report,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final CitizenReportSummary report;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.colorFor(report.categoryName);
    return PremiumSurface(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Semantics(
        button: true,
        label: 'Open assigned report ${report.title}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 40 : 48,
                  height: compact ? 40 : 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    CategoryColors.iconFor(report.categoryName),
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.categoryName ?? 'Uncategorized',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Case #${report.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                ReportStatusChip(status: report.status, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              report.title.isEmpty ? 'Untitled report' : report.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                StaffMetaChip(
                  icon: Icons.person_outline,
                  label: report.citizenName ?? 'Citizen unavailable',
                ),
                StaffMetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: _date(report.createdAt),
                ),
                if (report.address.trim().isNotEmpty)
                  StaffMetaChip(
                    icon: Icons.place_outlined,
                    label: report.address,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) {
      return 'Unknown date';
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
