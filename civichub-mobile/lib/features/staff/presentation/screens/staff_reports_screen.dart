import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../cubit/staff_reports_cubit.dart';
import '../cubit/staff_reports_state.dart';
import '../cubit/staff_workspace_cubit.dart';
import '../widgets/staff_section_header.dart';
import '../widgets/staff_report_card.dart';
import '../workflow/staff_queue_buckets.dart';
import '../workflow/staff_queue_session.dart';

class StaffReportsScreen extends StatelessWidget {
  const StaffReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StaffReportsCubit(
        staffRepository: context.read<StaffRepository>(),
        reportsRepository: context.read<ReportsRepository>(),
      )..loadInitial(),
      child: const _StaffReportsView(),
    );
  }
}

class _StaffReportsView extends StatefulWidget {
  const _StaffReportsView();

  @override
  State<_StaffReportsView> createState() => _StaffReportsViewState();
}

class _StaffReportsViewState extends State<_StaffReportsView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _citizenController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _citizenController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < 240) {
      context.read<StaffReportsCubit>().loadMore();
    }
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      context.read<StaffReportsCubit>().applySearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Reports')),
      body: CivicBackground(
        child: SafeArea(
          child: BlocListener<StaffWorkspaceCubit, StaffWorkspaceState>(
            listenWhen: (previous, current) =>
                previous.reportRefreshRevision != current.reportRefreshRevision,
            listener: (context, state) {
              context.read<StaffReportsCubit>().refresh();
            },
            child: BlocBuilder<StaffReportsCubit, StaffReportsState>(
              builder: (context, state) {
                StaffQueueSession.remember(state.reports);
                final buckets = StaffQueueBuckets.fromReports(state.reports);
                _syncControllers(state);
                return RefreshIndicator(
                  onRefresh: context.read<StaffReportsCubit>().refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: AppResponsive(
                            maxWidth: 1180,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _QueueHeader(buckets: buckets),
                                const SizedBox(height: AppSpacing.lg),
                                _FilterPanel(
                                  state: state,
                                  searchController: _searchController,
                                  citizenController: _citizenController,
                                  onSearchChanged: _queueSearch,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (state.isInitialLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: AppResponsive(
                              child: AppLoading(
                                message: 'Loading queue',
                                rows: 3,
                              ),
                            ),
                          ),
                        )
                      else if (state.status == StaffReportsStatus.failure &&
                          state.reports.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: AppResponsive(
                              child: AppError(
                                title: 'Unable to load assigned reports',
                                message:
                                    state.errorMessage ??
                                    'Please try again later.',
                                onRetry: context
                                    .read<StaffReportsCubit>()
                                    .retry,
                              ),
                            ),
                          ),
                        )
                      else if (state.reports.isEmpty)
                        _QueueEmpty(state: state).asSliver()
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: AppResponsive(
                              maxWidth: 1180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ProductivityBar(state: state),
                                  const SizedBox(height: AppSpacing.lg),
                                  _QueueSections(buckets: buckets),
                                ],
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: AppResponsive(
                            maxWidth: 1180,
                            child: _Footer(state: state),
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
      ),
    );
  }

  void _syncControllers(StaffReportsState state) {
    if (_searchController.text != state.search) {
      _searchController.text = state.search;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
    final citizenText = state.citizenIdFilter?.toString() ?? '';
    if (_citizenController.text != citizenText) {
      _citizenController.text = citizenText;
      _citizenController.selection = TextSelection.collapsed(
        offset: _citizenController.text.length,
      );
    }
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.buckets});

  final StaffQueueBuckets buckets;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff work queue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Triage, process, and close department-assigned reports without leaving your current queue context.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QueuePill(
                label: 'Needs attention',
                value: buckets.needsAttention.length,
              ),
              _QueuePill(
                label: 'In progress',
                value: buckets.inProgress.length,
              ),
              _QueuePill(label: 'Completed', value: buckets.completed.length),
            ],
          );
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.md),
                metrics,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.lg),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class _QueuePill extends StatelessWidget {
  const _QueuePill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.state,
    required this.searchController,
    required this.citizenController,
    required this.onSearchChanged,
  });

  final StaffReportsState state;
  final TextEditingController searchController;
  final TextEditingController citizenController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSectionHeader(
            title: 'Advanced filters',
            icon: Icons.tune_outlined,
            trailing: state.hasActiveFilters
                ? TextButton.icon(
                    onPressed: () {
                      searchController.clear();
                      citizenController.clear();
                      context.read<StaffReportsCubit>().clearFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear all'),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _filterSummary(state),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final search = Semantics(
                textField: true,
                label: 'Search assigned reports',
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onSubmitted: context.read<StaffReportsCubit>().applySearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search reports',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              context.read<StaffReportsCubit>().applySearch('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              );
              final citizen = Semantics(
                textField: true,
                label: 'Filter by citizen id',
                child: TextField(
                  controller: citizenController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: context
                      .read<StaffReportsCubit>()
                      .applyCitizenFilter,
                  decoration: InputDecoration(
                    hintText: 'Citizen ID',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    suffixIcon: state.citizenIdFilter == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear citizen filter',
                            onPressed: () {
                              citizenController.clear();
                              context
                                  .read<StaffReportsCubit>()
                                  .applyCitizenFilter('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              );
              if (!wide) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: AppSpacing.md),
                    citizen,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: search),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: citizen),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _DateRangeFilter(state: state),
          const SizedBox(height: AppSpacing.md),
          _StatusFilters(selected: state.statusFilter),
          if (state.categories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _CategoryFilters(state: state),
          ] else if (state.categoryErrorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppError(
              title: 'Categories did not load',
              message: state.categoryErrorMessage!,
              onRetry: context.read<StaffReportsCubit>().loadInitial,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sorting is backend-defined for staff reports; no sort parameters are exposed by this endpoint.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    final hasRange =
        state.createdFromFilter != null || state.createdToFilter != null;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickRange(context),
          icon: const Icon(Icons.date_range_outlined),
          label: Text(hasRange ? _dateRangeLabel(state) : 'Created date range'),
        ),
        if (hasRange)
          TextButton(
            onPressed: () =>
                context.read<StaffReportsCubit>().applyDateRange(null, null),
            child: const Text('Clear dates'),
          ),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final initialFirst =
        state.createdFromFilter ?? now.subtract(const Duration(days: 7));
    final initialLast = state.createdToFilter ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialFirst, end: initialLast),
    );
    if (!context.mounted || range == null) {
      return;
    }
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    await context.read<StaffReportsCubit>().applyDateRange(from, to);
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected});

  final ReportStatus? selected;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _FilterChipButton(
            label: 'All statuses',
            selected: selected == null,
            onTap: () =>
                context.read<StaffReportsCubit>().applyStatusFilter(null),
          ),
          for (final status in const [
            ReportStatus.pending,
            ReportStatus.received,
            ReportStatus.inProgress,
            ReportStatus.resolved,
            ReportStatus.rejected,
            ReportStatus.cancelled,
          ])
            _FilterChipButton(
              label: status.label,
              selected: selected == status,
              onTap: () =>
                  context.read<StaffReportsCubit>().applyStatusFilter(status),
            ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _FilterChipButton(
            label: 'All categories',
            selected: state.categoryIdFilter == null,
            onTap: () =>
                context.read<StaffReportsCubit>().applyCategoryFilter(null),
          ),
          for (final category in state.categories)
            _FilterChipButton(
              label: category.name,
              selected: state.categoryIdFilter == category.id,
              onTap: () => context
                  .read<StaffReportsCubit>()
                  .applyCategoryFilter(category.id),
            ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected ? AppColors.surface : AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      ),
    );
  }
}

class _ProductivityBar extends StatelessWidget {
  const _ProductivityBar({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    final oldestPending = context.read<StaffReportsCubit>().oldestPending;
    final nextReport = state.reports.firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final actions = [
          _ProductivityAction(
            label: 'Next report',
            icon: Icons.skip_next_outlined,
            enabled: nextReport != null,
            onTap: nextReport == null
                ? null
                : () => context.push(
                    AppRoutes.staffReportDetailPath(nextReport.id),
                  ),
          ),
          _ProductivityAction(
            label: 'Oldest pending',
            icon: Icons.history_toggle_off_outlined,
            enabled: oldestPending != null,
            onTap: oldestPending == null
                ? null
                : () => context.push(
                    AppRoutes.staffReportDetailPath(oldestPending.id),
                  ),
          ),
        ];
        if (!wide) {
          return Column(
            children: [
              for (final action in actions) ...[
                action,
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              Expanded(child: actions[index]),
              if (index != actions.length - 1)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _ProductivityAction extends StatelessWidget {
  const _ProductivityAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PremiumSurface(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        borderColor: enabled
            ? AppColors.primary.withValues(alpha: 0.24)
            : AppColors.line,
        child: Row(
          children: [
            Icon(icon, color: enabled ? AppColors.primary : AppColors.muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: enabled ? AppColors.ink : AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSections extends StatelessWidget {
  const _QueueSections({required this.buckets});

  final StaffQueueBuckets buckets;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _QueueSectionData(
        title: 'Needs Attention',
        emptyTitle: 'No pending work',
        emptyMessage: 'Pending and received reports will appear here.',
        reports: buckets.needsAttention,
      ),
      _QueueSectionData(
        title: 'In Progress',
        emptyTitle: 'Nothing in progress',
        emptyMessage: 'Reports being processed will appear here.',
        reports: buckets.inProgress,
      ),
      _QueueSectionData(
        title: 'Completed',
        emptyTitle: 'Everything here is still open',
        emptyMessage:
            'Resolved, rejected, and cancelled reports will appear here.',
        reports: buckets.completed,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1020 ? 3 : 1;
        if (columns == 1) {
          return Column(
            children: [
              for (final section in sections) ...[
                _QueueSection(section: section),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 720,
          ),
          itemBuilder: (context, index) =>
              _QueueSection(section: sections[index]),
        );
      },
    );
  }
}

class _QueueSectionData {
  const _QueueSectionData({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.reports,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final List<CitizenReportSummary> reports;
}

class _QueueSection extends StatelessWidget {
  const _QueueSection({required this.section});

  final _QueueSectionData section;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffSectionHeader(
            title: section.title,
            trailing: Text(
              '${section.reports.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (section.reports.isEmpty)
            AppEmpty(
              title: section.emptyTitle,
              message: section.emptyMessage,
              icon: Icons.inbox_outlined,
            )
          else
            for (final report in section.reports) ...[
              StaffReportCard(
                report: report,
                compact: true,
                onTap: () =>
                    context.push(AppRoutes.staffReportDetailPath(report.id)),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    if (state.hasActiveFilters) {
      return const AppEmpty(
        title: 'No reports match current filters',
        message: 'Clear or adjust filters to expand the queue.',
        icon: Icons.filter_alt_off_outlined,
      );
    }
    return const AppEmpty(
      title: 'Everything has been processed',
      message: 'No department reports are currently in this queue.',
      icon: Icons.done_all_outlined,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const AppLoading(message: 'Loading more', rows: 1);
    }
    if (state.paginationErrorMessage != null) {
      return AppError(
        title: 'More reports did not load',
        message: state.paginationErrorMessage!,
        onRetry: context.read<StaffReportsCubit>().loadMore,
      );
    }
    if (state.reports.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      state.hasReachedEnd
          ? '${state.totalElements} assigned reports'
          : 'Showing ${state.reports.length} of ${state.totalElements}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

String _filterSummary(StaffReportsState state) {
  if (!state.hasActiveFilters) {
    return 'Showing backend-scoped department reports.';
  }
  final parts = <String>[];
  if (state.search.isNotEmpty) {
    parts.add('Search "${state.search}"');
  }
  if (state.statusFilter != null) {
    parts.add('Status ${state.statusFilter!.label}');
  }
  if (state.categoryIdFilter != null) {
    parts.add('Category #${state.categoryIdFilter}');
  }
  if (state.citizenIdFilter != null) {
    parts.add('Citizen #${state.citizenIdFilter}');
  }
  if (state.createdFromFilter != null || state.createdToFilter != null) {
    parts.add(_dateRangeLabel(state));
  }
  return parts.join(' • ');
}

String _dateRangeLabel(StaffReportsState state) {
  final from = _date(state.createdFromFilter);
  final to = _date(state.createdToFilter);
  return '$from to $to';
}

String _date(DateTime? value) {
  if (value == null) {
    return 'Any date';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

extension on List<CitizenReportSummary> {
  CitizenReportSummary? get firstOrNull => isEmpty ? null : first;
}

extension on Widget {
  Widget asSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: this),
    );
  }
}
