import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../domain/models/report_summary.dart';
import '../cubit/reports_cubit.dart';
import 'report_status_chip.dart';

class ReportsList extends StatelessWidget {
  const ReportsList({super.key, required this.reports});

  final List<CitizenReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 900;
        if (useGrid) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 252,
            ),
            itemBuilder: (context, index) => ReportCard(report: reports[index]),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => ReportCard(report: reports[index]),
        );
      },
    );
  }
}

class ReportCard extends StatefulWidget {
  const ReportCard({super.key, required this.report});

  final CitizenReportSummary report;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _hovered = false;
  bool _focused = false;

  CitizenReportSummary get report => widget.report;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.colorFor(report.categoryName);
    final active = _hovered || _focused;
    final borderColor = active
        ? categoryColor.withValues(alpha: 0.42)
        : AppColors.line;

    return Semantics(
      button: true,
      label: 'Open report ${report.title}',
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        mouseCursor: SystemMouseCursors.click,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, active ? -2 : 0, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: active ? 0.1 : 0.05),
                  blurRadius: active ? 22 : 14,
                  offset: Offset(0, active ? 12 : 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openReport(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTopline(report: report, color: categoryColor),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        report.title.isEmpty ? 'Untitled report' : report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CaseMetaGrid(report: report),
                      if (report.address.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _AddressLine(address: report.address),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _CardFooter(report: report, color: categoryColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReport(BuildContext context) async {
    final changed = await context.push<bool>(
      AppRoutes.reportDetailPath(report.id),
    );
    if (!context.mounted || changed != true) {
      return;
    }
    await context.read<ReportsCubit>().refresh();
  }
}

class _CardTopline extends StatelessWidget {
  const _CardTopline({required this.report, required this.color});

  final CitizenReportSummary report;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final category = report.categoryName ?? 'Uncategorized';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(CategoryColors.iconFor(category), color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
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
    );
  }
}

class _CaseMetaGrid extends StatelessWidget {
  const _CaseMetaGrid({required this.report});

  final CitizenReportSummary report;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _CaseMeta(
          icon: Icons.apartment_outlined,
          label: report.departmentName ?? 'Unassigned',
        ),
        _CaseMeta(
          icon: Icons.calendar_today_outlined,
          label: _date(report.createdAt),
        ),
      ],
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

class _CaseMeta extends StatelessWidget {
  const _CaseMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.report, required this.color});

  final CitizenReportSummary report;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _updatedText(report.updatedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.arrow_forward, size: 18, color: color),
        ),
      ],
    );
  }

  String _updatedText(DateTime? value) {
    if (value == null) {
      return 'Open details';
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'Updated ${local.year}-$month-$day';
  }
}
