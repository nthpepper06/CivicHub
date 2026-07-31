import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/report_summary.dart';
import '../cubit/reports_cubit.dart';

class ReportsList extends StatelessWidget {
  const ReportsList({super.key, required this.reports});

  final List<CitizenReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList.separated(
        itemCount: reports.length,
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.xl),
        itemBuilder: (context, index) {
          return ReportCard(report: reports[index]);
        },
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final CitizenReportSummary report;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => _openReport(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ReportThumbnail(imageUrl: report.primaryImageUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _ReportSummaryText(report: report)),
            const SizedBox(width: AppSpacing.sm),
            _ReportTrailing(status: report.status),
          ],
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

class _ReportThumbnail extends StatelessWidget {
  const _ReportThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: 60,
        height: 60,
        child: imageUrl == null
            ? const _ReportImageFallback(icon: Icons.assignment_outlined)
            : AppNetworkImage(
                url: imageUrl!,
                fit: BoxFit.cover,
                logicalWidth: 60,
                logicalHeight: 60,
                fallback: const _ReportImageFallback(
                  icon: Icons.broken_image_outlined,
                ),
              ),
      ),
    );
  }
}

class _ReportImageFallback extends StatelessWidget {
  const _ReportImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.softIcon,
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _ReportSummaryText extends StatelessWidget {
  const _ReportSummaryText({required this.report});

  final CitizenReportSummary report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.title.isEmpty ? 'Untitled report' : report.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          report.address.isEmpty ? 'No address provided' : report.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          report.categoryName ?? 'Uncategorized',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _ReportTrailing extends StatelessWidget {
  const _ReportTrailing({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ReportStatusPill(status: status),
        const SizedBox(height: AppSpacing.sm),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ],
    );
  }
}

class ReportStatusPill extends StatelessWidget {
  const ReportStatusPill({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Color get _color {
    return switch (status) {
      ReportStatus.pending => AppColors.warning,
      ReportStatus.received => AppColors.primary,
      ReportStatus.inProgress => AppColors.primaryDark,
      ReportStatus.resolved => AppColors.success,
      ReportStatus.rejected => AppColors.danger,
      ReportStatus.cancelled => AppColors.muted,
      ReportStatus.unknown => AppColors.muted,
    };
  }
}
