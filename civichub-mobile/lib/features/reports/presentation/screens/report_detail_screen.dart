import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/location/location_point.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/location_map.dart';
import '../../../../core/widgets/location_preview_card.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../domain/models/report_detail.dart';
import '../../domain/models/report_status.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/report_detail_cubit.dart';
import '../cubit/report_detail_state.dart';
import '../widgets/report_status_chip.dart';

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
    return const _ReportDetailScaffold();
  }
}

class _ReportDetailScaffold extends StatefulWidget {
  const _ReportDetailScaffold();

  @override
  State<_ReportDetailScaffold> createState() => _ReportDetailScaffoldState();
}

class _ReportDetailScaffoldState extends State<_ReportDetailScaffold> {
  bool _changed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_changed);
        }
      },
      child: BlocListener<ReportDetailCubit, ReportDetailState>(
        listenWhen: (previous, current) =>
            previous.actionSucceeded != current.actionSucceeded ||
            previous.actionErrorMessage != current.actionErrorMessage,
        listener: (context, state) {
          if (state.actionSucceeded) {
            _changed = true;
            AppFeedback.show(
              context,
              message: 'Report cancelled.',
              type: AppFeedbackType.success,
            );
          } else if (state.actionErrorMessage != null) {
            AppFeedback.show(
              context,
              message: state.actionErrorMessage!,
              type: AppFeedbackType.error,
            );
          }
        },
        child: BlocBuilder<ReportDetailCubit, ReportDetailState>(
          builder: (context, state) {
            final report = state.report;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Report Detail'),
                leading: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(_changed),
                ),
                actions: [
                  if (report?.status == ReportStatus.pending) ...[
                    IconButton(
                      tooltip: 'Edit report',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: state.isCancelling
                          ? null
                          : () async {
                              final edited = await context.push<bool>(
                                AppRoutes.editReportPath(report!.id),
                                extra: report,
                              );
                              if (!context.mounted || edited != true) {
                                return;
                              }
                              _changed = true;
                              await context.read<ReportDetailCubit>().load();
                              if (!context.mounted) {
                                return;
                              }
                              AppFeedback.show(
                                context,
                                message: 'Report updated.',
                                type: AppFeedbackType.success,
                              );
                            },
                    ),
                    IconButton(
                      tooltip: 'Cancel report',
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: state.isCancelling
                          ? null
                          : () => _confirmCancel(context),
                    ),
                  ],
                ],
              ),
              body: CivicBackground(
                child: SafeArea(
                  child: switch (state.status) {
                    ReportDetailStatus.initial ||
                    ReportDetailStatus.loading => const Center(
                      child: AppLoading(message: 'Loading report'),
                    ),
                    ReportDetailStatus.empty => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppEmpty(
                        title: 'Report not found',
                        message:
                            state.errorMessage ?? 'This report is unavailable.',
                        icon: Icons.assignment_late_outlined,
                      ),
                    ),
                    ReportDetailStatus.failure => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppError(
                        title: state.isUnauthorized
                            ? 'Session required'
                            : 'Unable to load report',
                        message:
                            state.errorMessage ?? 'Please try again later.',
                        onRetry: context.read<ReportDetailCubit>().retry,
                      ),
                    ),
                    ReportDetailStatus.success => _DetailContent(
                      report: state.report,
                      isCancelling: state.isCancelling,
                    ),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel this report?'),
          content: const Text('Only pending reports can be cancelled.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }
    await context.read<ReportDetailCubit>().cancel();
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Only pending reports can be edited or cancelled.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellingNotice extends StatelessWidget {
  const _CancellingNotice();

  @override
  Widget build(BuildContext context) {
    return const PremiumSurface(
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Cancelling report...')),
        ],
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.report, required this.isCancelling});

  final CitizenReportDetail? report;
  final bool isCancelling;

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
        AppResponsive(
          maxWidth: 920,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCancelling) ...[
                const _CancellingNotice(),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (detail.status != ReportStatus.pending) ...[
                const _ReadOnlyNotice(),
                const SizedBox(height: AppSpacing.lg),
              ],
              PremiumSurface(
                gradient: AppGradients.cityHero,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportStatusChip(status: detail.status),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      detail.title.isEmpty ? 'Untitled report' : detail.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.surface),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      detail.description.isEmpty
                          ? 'No description provided.'
                          : detail.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              LocationPreviewCard(
                address: detail.address,
                point: _locationPoint(detail),
                onOpen: _locationPoint(detail) == null
                    ? null
                    : () => _showLocationMap(context, detail),
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
          ),
        ),
      ],
    );
  }

  LocationPoint? _locationPoint(CitizenReportDetail detail) {
    final latitude = detail.latitude;
    final longitude = detail.longitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    final point = LocationPoint(latitude: latitude, longitude: longitude);
    return point.isValid ? point : null;
  }

  void _showLocationMap(BuildContext context, CitizenReportDetail detail) {
    final point = _locationPoint(detail);
    if (point == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    detail.address.trim().isEmpty
                        ? 'Report location'
                        : detail.address.trim(),
                  ),
                  subtitle: Text(point.coordinatesLabel),
                  trailing: IconButton(
                    tooltip: 'Close map',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Expanded(
                  child: LocationMap(
                    point: point,
                    height: double.infinity,
                    interactive: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    return PremiumSurface(
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
              child: AppNetworkImage(
                url: image.url,
                semanticLabel: 'Report image ${image.displayOrder + 1}',
                fit: BoxFit.cover,
                logicalWidth: 720,
                logicalHeight: 405,
                fallback: const ColoredBox(
                  color: AppColors.softIcon,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
