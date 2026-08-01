import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../reports/domain/models/report_detail.dart';
import '../../../reports/presentation/widgets/report_status_chip.dart';
import '../../domain/repositories/staff_repository.dart';
import '../cubit/staff_report_detail_cubit.dart';
import '../cubit/staff_report_detail_state.dart';

class StaffReportDetailScreen extends StatelessWidget {
  const StaffReportDetailScreen({required this.reportId, super.key});

  final int reportId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StaffReportDetailCubit(
        staffRepository: context.read<StaffRepository>(),
        reportId: reportId,
      )..load(),
      child: const _StaffReportDetailView(),
    );
  }
}

class _StaffReportDetailView extends StatelessWidget {
  const _StaffReportDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Report')),
      body: CivicBackground(
        child: SafeArea(
          child: BlocBuilder<StaffReportDetailCubit, StaffReportDetailState>(
            builder: (context, state) {
              if (state.isInitialLoading) {
                return const AppResponsive(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: AppLoading(
                      message: 'Loading assigned report',
                      rows: 5,
                    ),
                  ),
                );
              }
              if (state.status == StaffReportDetailStatus.failure &&
                  state.report == null) {
                return AppResponsive(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppError(
                      title: 'Unable to load assigned report',
                      message: state.errorMessage ?? 'Please try again later.',
                      onRetry: context.read<StaffReportDetailCubit>().retry,
                    ),
                  ),
                );
              }
              final report = state.report;
              if (report == null) {
                return const AppEmpty(
                  title: 'Assigned report unavailable',
                  message:
                      'This report could not be found for your department.',
                  icon: Icons.assignment_late_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<StaffReportDetailCubit>().refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: AppResponsive(
                          maxWidth: 920,
                          child: _ReportDetailContent(report: report),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportDetailContent extends StatelessWidget {
  const _ReportDetailContent({required this.report});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.colorFor(report.categoryName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSurface(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      CategoryColors.iconFor(report.categoryName),
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.categoryName ?? 'Uncategorized',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          report.title.isEmpty
                              ? 'Untitled report'
                              : report.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ReportStatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _MetaGrid(report: report),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumSurface(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                report.description.trim().isEmpty
                    ? 'No description provided.'
                    : report.description.trim(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.82),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (report.images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ImagesPanel(images: report.images),
        ],
      ],
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.report});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetaItem(
        icon: Icons.person_outline,
        label: 'Citizen',
        value: report.citizenName ?? 'Unavailable',
      ),
      _MetaItem(
        icon: Icons.apartment_outlined,
        label: 'Department',
        value: report.departmentName ?? 'Your department',
      ),
      _MetaItem(
        icon: Icons.calendar_today_outlined,
        label: 'Created',
        value: _date(report.createdAt),
      ),
      if (report.address.trim().isNotEmpty)
        _MetaItem(
          icon: Icons.place_outlined,
          label: 'Address',
          value: report.address.trim(),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 74,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesPanel extends StatelessWidget {
  const _ImagesPanel({required this.images});

  final List<ReportImage> images;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Images',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final image = images[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    image.url,
                    width: 148,
                    height: 112,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 148,
                      height: 112,
                      color: AppColors.surfaceAlt,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
