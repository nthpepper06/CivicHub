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
  const ReportDetailScreen({required this.reportId, this.focus, super.key});

  final int reportId;
  final String? focus;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportDetailCubit(
        reportsRepository: context.read<ReportsRepository>(),
        reportId: reportId,
      )..load(),
      child: _ReportDetailView(focus: focus),
    );
  }
}

class _ReportDetailView extends StatelessWidget {
  const _ReportDetailView({this.focus});

  final String? focus;

  @override
  Widget build(BuildContext context) {
    return _ReportDetailScaffold(focus: focus);
  }
}

class _ReportDetailScaffold extends StatefulWidget {
  const _ReportDetailScaffold({this.focus});

  final String? focus;

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
            previous.actionErrorMessage != current.actionErrorMessage ||
            previous.actionSuccessMessage != current.actionSuccessMessage,
        listener: (context, state) {
          if (state.actionSucceeded) {
            _changed = true;
            AppFeedback.show(
              context,
              message: state.actionSuccessMessage ?? 'Report updated.',
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
                      isSubmittingFeedback: state.isSubmittingFeedback,
                      focus: widget.focus,
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

class _DeepLinkFocusNotice extends StatelessWidget {
  const _DeepLinkFocusNotice({required this.focus});

  final String focus;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      child: Row(
        children: [
          const Icon(Icons.notification_important_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              focus == 'resolution'
                  ? 'Opened from a resolution notification.'
                  : 'Opened from a timeline notification.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.report,
    required this.isCancelling,
    required this.isSubmittingFeedback,
    this.focus,
  });

  final CitizenReportDetail? report;
  final bool isCancelling;
  final bool isSubmittingFeedback;
  final String? focus;

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
              if (focus == 'resolution' || focus == 'timeline') ...[
                _DeepLinkFocusNotice(focus: focus!),
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
              _TimelineSection(events: detail.timeline),
              const SizedBox(height: AppSpacing.lg),
              _ImagesSection(
                title: 'Before photos',
                emptyTitle: 'No before photos',
                emptyMessage: 'This report does not include initial photos.',
                images: detail.images,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ResolutionSection(resolution: detail.resolution),
              const SizedBox(height: AppSpacing.lg),
              _FeedbackSection(
                report: detail,
                isSubmitting: isSubmittingFeedback,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                title: 'Metadata',
                children: [
                  _InfoRow(label: 'Created', value: _date(detail.createdAt)),
                  _InfoRow(label: 'Updated', value: _date(detail.updatedAt)),
                ],
              ),
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

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.events});

  final List<ReportTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const AppEmpty(
        title: 'No timeline yet',
        message: 'Lifecycle events will appear here as this report progresses.',
        icon: Icons.timeline_outlined,
      );
    }
    return _Section(
      title: 'Timeline',
      children: [
        for (final event in events) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.radio_button_checked, size: 18),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title.isEmpty ? event.type : event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        event.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        if (event.actorName != null) event.actorName,
                        _dateLabel(event.createdAt),
                      ].whereType<String>().join(' • '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ResolutionSection extends StatelessWidget {
  const _ResolutionSection({required this.resolution});

  final ReportResolution? resolution;

  @override
  Widget build(BuildContext context) {
    final data = resolution;
    if (data == null) {
      return const AppEmpty(
        title: 'No resolution yet',
        message:
            'Resolution notes and after photos will appear after staff completes the work.',
        icon: Icons.task_alt_outlined,
      );
    }
    return _Section(
      title: 'Resolution',
      children: [
        _InfoRow(label: 'Summary', value: data.summary),
        _InfoRow(label: 'Work performed', value: data.workPerformed),
        _InfoRow(label: 'Public note', value: data.publicNote),
        _InfoRow(label: 'Resolved by', value: data.resolvedByName),
        _InfoRow(label: 'Resolved at', value: _dateLabel(data.resolvedAt)),
        const SizedBox(height: AppSpacing.md),
        _ImagesSection(
          title: 'After photos',
          emptyTitle: 'No after photos',
          emptyMessage: 'Staff did not attach resolution photos.',
          images: data.images,
        ),
      ],
    );
  }
}

class _FeedbackSection extends StatefulWidget {
  const _FeedbackSection({required this.report, required this.isSubmitting});

  final CitizenReportDetail report;
  final bool isSubmitting;

  @override
  State<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<_FeedbackSection> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rating = widget.report.rating;
    if (rating != null && rating.rating > 0) {
      _rating = rating.rating;
      _commentController.text = rating.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    if (report.status != ReportStatus.resolved) {
      return const SizedBox.shrink();
    }
    final resolution = report.resolution;
    return _Section(
      title: 'Citizen feedback',
      children: [
        if (resolution?.isConfirmed == true)
          _InfoRow(
            label: 'Confirmation',
            value:
                'Confirmed at ${_dateLabel(resolution?.citizenConfirmedAt) ?? 'unknown time'}',
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.isSubmitting
                  ? null
                  : context.read<ReportDetailCubit>().confirmResolution,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Confirm Resolution'),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var index = 1; index <= 5; index++)
              IconButton(
                tooltip: 'Rate $index stars',
                onPressed: widget.isSubmitting
                    ? null
                    : () => setState(() => _rating = index),
                icon: Icon(
                  index <= _rating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                ),
              ),
          ],
        ),
        TextField(
          controller: _commentController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Optional comment',
            hintText: 'Share feedback about the resolution',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.isSubmitting
                ? null
                : () => context.read<ReportDetailCubit>().rateResolution(
                    _rating,
                    comment: _commentController.text,
                  ),
            icon: widget.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.rate_review_outlined),
            label: Text(
              report.rating == null ? 'Submit Rating' : 'Update Rating',
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagesSection extends StatelessWidget {
  const _ImagesSection({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.images,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final List<ReportImage> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return AppEmpty(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.image_not_supported_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
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

String? _dateLabel(DateTime? value) {
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
