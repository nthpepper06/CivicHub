import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/models/report_detail.dart';
import '../../domain/models/report_status.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/report_detail_cubit.dart';
import '../cubit/report_detail_state.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({required this.reportId, super.key});

  final int reportId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportDetailCubit(
        reportsRepository: context.read<ReportsRepository>(),
        reportId: reportId,
      )..load(),
      child: const _ReportDetailView(),
    );
  }
}

class _ReportDetailView extends StatelessWidget {
  const _ReportDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Detail')),
      body: SafeArea(
        child: BlocBuilder<ReportDetailCubit, ReportDetailState>(
          builder: (context, state) {
            return switch (state.status) {
              ReportDetailStatus.initial || ReportDetailStatus.loading =>
                const Center(child: AppLoading(message: 'Loading report')),
              ReportDetailStatus.empty => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppEmpty(
                  title: 'Report not found',
                  message: state.errorMessage ?? 'This report is unavailable.',
                  icon: Icons.assignment_late_outlined,
                ),
              ),
              ReportDetailStatus.failure => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppError(
                  title: state.isUnauthorized
                      ? 'Session required'
                      : 'Unable to load report',
                  message: state.errorMessage ?? 'Please try again later.',
                  onRetry: context.read<ReportDetailCubit>().retry,
                ),
              ),
              ReportDetailStatus.success => _DetailContent(
                report: state.report,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.report});

  final CitizenReportDetail? report;

  @override
  Widget build(BuildContext context) {
    final detail = report;
    if (detail == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AppEmpty(
          title: 'Report not found',
          message: 'This report is unavailable.',
          icon: Icons.assignment_late_outlined,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail.title.isEmpty ? 'Untitled report' : detail.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _StatusPill(status: detail.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          detail.description.isEmpty
              ? 'No description provided.'
              : detail.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(
          title: 'Location',
          children: [
            _InfoRow(label: 'Address', value: detail.address),
            _InfoRow(label: 'Latitude', value: _number(detail.latitude)),
            _InfoRow(label: 'Longitude', value: _number(detail.longitude)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Classification',
          children: [
            _InfoRow(label: 'Category', value: detail.categoryName),
            _InfoRow(label: 'Department', value: detail.departmentName),
            _InfoRow(label: 'Citizen', value: detail.citizenName),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Timeline',
          children: [
            _InfoRow(label: 'Created', value: _date(detail.createdAt)),
            _InfoRow(label: 'Updated', value: _date(detail.updatedAt)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ImagesSection(images: detail.images),
      ],
    );
  }

  String? _number(double? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  String? _date(DateTime? value) {
    if (value == null) {
      return null;
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value == null || value!.trim().isEmpty ? '-' : value!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesSection extends StatelessWidget {
  const _ImagesSection({required this.images});

  final List<ReportImage> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const AppEmpty(
        title: 'No images',
        message: 'This report does not include image attachments.',
        icon: Icons.image_not_supported_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final image in images) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                image.url,
                semanticLabel: 'Report image ${image.displayOrder + 1}',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const ColoredBox(
                    color: AppColors.softIcon,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: AppColors.softIcon,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

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
