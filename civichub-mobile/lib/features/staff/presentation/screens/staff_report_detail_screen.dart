import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/location/location_point.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/location_map.dart';
import '../../../../core/widgets/location_preview_card.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../reports/domain/models/report_detail.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/presentation/widgets/report_status_chip.dart';
import '../../domain/repositories/staff_repository.dart';
import '../cubit/staff_report_detail_cubit.dart';
import '../cubit/staff_report_detail_state.dart';
import '../cubit/staff_workspace_cubit.dart';
import '../widgets/staff_section_header.dart';
import '../workflow/staff_queue_session.dart';

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
    return BlocConsumer<StaffReportDetailCubit, StaffReportDetailState>(
      listenWhen: (previous, current) =>
          previous.updateErrorMessage != current.updateErrorMessage ||
          previous.updateSuccessMessage != current.updateSuccessMessage,
      listener: (context, state) {
        final error = state.updateErrorMessage;
        final success = state.updateSuccessMessage;
        if (error != null) {
          AppFeedback.show(
            context,
            message: error,
            type: AppFeedbackType.error,
          );
        } else if (success != null) {
          AppFeedback.show(
            context,
            message: success,
            type: AppFeedbackType.success,
          );
          context.read<StaffWorkspaceCubit>().reportWorkflowUpdated();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Assigned Report')),
          body: CivicBackground(
            child: SafeArea(child: _DetailBody(state: state)),
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state});

  final StaffReportDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const AppResponsive(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppLoading(message: 'Loading assigned report', rows: 5),
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
        message: 'This report could not be found for your department.',
        icon: Icons.assignment_late_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<StaffReportDetailCubit>().refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: AppResponsive(
                maxWidth: 1180,
                child: _ResponsiveDetail(report: report, state: state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveDetail extends StatelessWidget {
  const _ResponsiveDetail({required this.report, required this.state});

  final CitizenReportDetail report;
  final StaffReportDetailState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 900;
        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroPanel(report: report),
            const SizedBox(height: AppSpacing.lg),
            _QueueNavigationPanel(reportId: report.id),
            const SizedBox(height: AppSpacing.lg),
            _DescriptionPanel(report: report),
            const SizedBox(height: AppSpacing.lg),
            LocationPreviewCard(
              title: 'Report location',
              address: report.address,
              point: _locationPoint(report),
              onOpen: _locationPoint(report) == null
                  ? null
                  : () => _showLocationMap(context, report),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ImagesPanel(images: report.images),
          ],
        );
        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusWorkflowPanel(state: state),
            const SizedBox(height: AppSpacing.lg),
            _CurrentStatePanel(report: report),
          ],
        );
        if (!useColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              const SizedBox(height: AppSpacing.lg),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: main),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 4, child: side),
          ],
        );
      },
    );
  }
}

LocationPoint? _locationPoint(CitizenReportDetail report) {
  final latitude = report.latitude;
  final longitude = report.longitude;
  if (latitude == null || longitude == null) {
    return null;
  }
  final point = LocationPoint(latitude: latitude, longitude: longitude);
  return point.isValid ? point : null;
}

void _showLocationMap(BuildContext context, CitizenReportDetail report) {
  final point = _locationPoint(report);
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
                  report.address.trim().isEmpty
                      ? 'Report location'
                      : report.address.trim(),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.report});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColors.colorFor(report.categoryName);
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      report.title.isEmpty ? 'Untitled report' : report.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: AppSpacing.sm),
                _LargeStatusBadge(status: report.status),
              ],
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              if (compact) ...[
                const SizedBox(height: AppSpacing.md),
                _LargeStatusBadge(status: report.status),
              ],
              const SizedBox(height: AppSpacing.lg),
              _MetaGrid(report: report),
            ],
          );
        },
      ),
    );
  }
}

class _QueueNavigationPanel extends StatelessWidget {
  const _QueueNavigationPanel({required this.reportId});

  final int reportId;

  @override
  Widget build(BuildContext context) {
    final previousButton = Tooltip(
      message: 'Open the previous report from this queue',
      child: OutlinedButton(
        onPressed: () {
          final target = StaffQueueSession.previous(reportId);
          if (target == null) {
            return;
          }
          context.pushReplacement(AppRoutes.staffReportDetailPath(target.id));
        },
        child: const _ActionButtonContent(
          icon: Icons.arrow_back,
          label: 'Previous report',
        ),
      ),
    );
    final queueButton = Tooltip(
      message: 'Return to assigned reports with current filters',
      child: FilledButton(
        onPressed: () => context.go(AppRoutes.staffReports),
        child: const _ActionButtonContent(
          icon: Icons.view_kanban_outlined,
          label: 'Return to queue',
        ),
      ),
    );
    final nextButton = Tooltip(
      message: 'Open the next report from this queue',
      child: OutlinedButton(
        onPressed: () {
          final target = StaffQueueSession.next(reportId);
          if (target == null) {
            return;
          }
          context.pushReplacement(AppRoutes.staffReportDetailPath(target.id));
        },
        child: const _ActionButtonContent(
          icon: Icons.arrow_forward,
          label: 'Next report',
        ),
      ),
    );
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                previousButton,
                const SizedBox(height: AppSpacing.sm),
                queueButton,
                const SizedBox(height: AppSpacing.sm),
                nextButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: previousButton),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: queueButton),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: nextButton),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtonContent extends StatelessWidget {
  const _ActionButtonContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.report});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    final coordinate = _coordinates(report);
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
        value: _dateTime(report.createdAt),
      ),
      if (report.address.trim().isNotEmpty)
        _MetaItem(
          icon: Icons.place_outlined,
          label: 'Address',
          value: report.address.trim(),
        ),
      if (coordinate != null)
        _MetaItem(
          icon: Icons.explore_outlined,
          label: 'Coordinates',
          value: coordinate,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 76,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  String? _coordinates(CitizenReportDetail report) {
    final latitude = report.latitude;
    final longitude = report.longitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
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

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({required this.report});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffSectionHeader(title: 'Description'),
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
    );
  }
}

class _StatusWorkflowPanel extends StatelessWidget {
  const _StatusWorkflowPanel({required this.state});

  final StaffReportDetailState state;

  @override
  Widget build(BuildContext context) {
    final report = state.report!;
    final actions = state.availableActions;
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffSectionHeader(
            title: 'Workflow',
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ReportStatusChip(status: report.status),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Current status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (actions.isEmpty)
            _WorkflowClosed(status: report.status)
          else
            for (final action in actions) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isUpdatingStatus
                      ? null
                      : () => _handleStatusAction(context, action),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.updatingStatus == action)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(_statusIcon(action), size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'Mark ${action.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  Future<void> _handleStatusAction(
    BuildContext context,
    ReportStatus action,
  ) async {
    final confirmed = await _confirmTerminalAction(context, action);
    if (!context.mounted || !confirmed) {
      return;
    }
    await context.read<StaffReportDetailCubit>().updateStatus(action);
  }

  Future<bool> _confirmTerminalAction(
    BuildContext context,
    ReportStatus action,
  ) async {
    final content = _terminalConfirmation(action);
    if (content == null) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(content.title),
              content: Text(content.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _WorkflowClosed extends StatelessWidget {
  const _WorkflowClosed({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final content = _terminalWorkflowContent(status);
    final color = statusColorFor(status.apiValue);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(content.icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    content.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.35,
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

class _CurrentStatePanel extends StatelessWidget {
  const _CurrentStatePanel({required this.report});

  final CitizenReportDetail report;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffSectionHeader(
            title: 'Current state',
            icon: Icons.track_changes_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColorFor(
                    report.status.apiValue,
                  ).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(report.status),
                  color: statusColorFor(report.status.apiValue),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.status.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _currentStateDescription(report.status),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    if (report.updatedAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _dateTime(report.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
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
          StaffSectionHeader(
            title: images.isEmpty
                ? 'Attachments'
                : 'Attachments (${images.length})',
            icon: Icons.attach_file_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          if (images.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.attach_file_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'No attachments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 640 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: 154,
                  ),
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return Semantics(
                      button: true,
                      label: 'Preview report image ${index + 1}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () => _showImagePreview(context, image.url),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.network(
                              image.url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.surfaceAlt,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.muted,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: AppColors.navy,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.surface,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: IconButton.filled(
                    tooltip: 'Close image preview',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LargeStatusBadge extends StatelessWidget {
  const _LargeStatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColorFor(status.apiValue);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(status), size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({String title, String message, IconData icon}) _terminalWorkflowContent(
  ReportStatus status,
) {
  return switch (status) {
    ReportStatus.resolved => (
      title: 'Workflow completed',
      message:
          'This report has reached its final status. No further staff action is required.',
      icon: Icons.check_circle_outline,
    ),
    ReportStatus.rejected => (
      title: 'Case closed',
      message:
          'This report has been rejected and no further staff action is available.',
      icon: Icons.block_outlined,
    ),
    ReportStatus.cancelled => (
      title: 'Case cancelled',
      message: 'This report was cancelled and cannot be processed further.',
      icon: Icons.cancel_outlined,
    ),
    _ => (
      title: 'Workflow paused',
      message: 'No further staff action is available for this status.',
      icon: Icons.info_outline,
    ),
  };
}

({String title, String message})? _terminalConfirmation(ReportStatus status) {
  return switch (status) {
    ReportStatus.resolved => (
      title: 'Mark this report as resolved?',
      message: 'This action moves the report to a final status.',
    ),
    ReportStatus.rejected => (
      title: 'Reject this report?',
      message: 'This action moves the report to a final status.',
    ),
    _ => null,
  };
}

String _currentStateDescription(ReportStatus status) {
  return switch (status) {
    ReportStatus.resolved ||
    ReportStatus.rejected ||
    ReportStatus.cancelled => 'Latest final status from the report record.',
    _ => 'Latest status from the report record.',
  };
}

IconData _statusIcon(ReportStatus status) {
  return switch (status) {
    ReportStatus.pending => Icons.hourglass_empty_outlined,
    ReportStatus.received => Icons.move_to_inbox_outlined,
    ReportStatus.inProgress => Icons.construction_outlined,
    ReportStatus.resolved => Icons.verified_outlined,
    ReportStatus.rejected => Icons.block_outlined,
    ReportStatus.cancelled => Icons.cancel_outlined,
    ReportStatus.unknown => Icons.help_outline,
  };
}

String _dateTime(DateTime? value) {
  if (value == null) {
    return 'Unknown time';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
