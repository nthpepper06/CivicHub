import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ReportsCubit(reportsRepository: context.read<ReportsRepository>())
            ..loadInitial(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter < 240) {
      context.read<ReportsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(
            tooltip: 'Create report',
            onPressed: () async {
              final created = await context.push<bool>(AppRoutes.createReport);
              if (!context.mounted || created != true) {
                return;
              }
              await context.read<ReportsCubit>().refresh();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted.')),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<ReportsCubit>().refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(child: _Header(state: state)),
                  ),
                  if (state.isInitialLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppLoading(message: 'Loading reports'),
                      ),
                    )
                  else if (state.status == ReportsStatus.failure &&
                      state.reports.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppError(
                          title: 'Unable to load reports',
                          message:
                              state.errorMessage ?? 'Please try again later.',
                          onRetry: context.read<ReportsCubit>().retry,
                        ),
                      ),
                    )
                  else if (state.reports.isEmpty)
                    const AppEmpty(
                      title: 'No reports yet',
                      message:
                          'Submitted reports will appear here once they are created.',
                      icon: Icons.assignment_outlined,
                    ).asSliver()
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverList.separated(
                        itemCount: state.reports.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: AppSpacing.xl),
                        itemBuilder: (context, index) {
                          return _ReportRow(report: state.reports[index]);
                        },
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: _PaginationFooter(state: state),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reports', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            onSubmitted: context.read<ReportsCubit>().applySearch,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search reports',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatusChip(
              label: 'All',
              selected: state.statusFilter == null,
              onSelected: () =>
                  context.read<ReportsCubit>().applyStatusFilter(null),
            ),
            for (final status in const [
              ReportStatus.pending,
              ReportStatus.received,
              ReportStatus.inProgress,
              ReportStatus.resolved,
              ReportStatus.rejected,
              ReportStatus.cancelled,
            ])
              _StatusChip(
                label: status.label,
                selected: state.statusFilter == status,
                onSelected: () =>
                    context.read<ReportsCubit>().applyStatusFilter(status),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppLoading(message: 'Loading more reports'),
      );
    }

    final paginationError = state.paginationErrorMessage;
    if (paginationError != null) {
      return AppError(
        title: 'More reports did not load',
        message: paginationError,
        onRetry: context.read<ReportsCubit>().loadMore,
      );
    }

    if (state.reports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      state.hasReachedEnd
          ? '${state.totalElements} reports'
          : 'Showing ${state.reports.length} of ${state.totalElements}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

extension on Widget {
  Widget asSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: this),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final CitizenReportSummary report;

  @override
  Widget build(BuildContext context) {
    final imageUrl = report.primaryImageUrl;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () async {
        final changed = await context.push<bool>(
          AppRoutes.reportDetailPath(report.id),
        );
        if (!context.mounted || changed != true) {
          return;
        }
        await context.read<ReportsCubit>().refresh();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 60,
                height: 60,
                child: imageUrl == null
                    ? ColoredBox(
                        color: AppColors.softIcon,
                        child: Icon(
                          Icons.assignment_outlined,
                          color: AppColors.primary,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: AppColors.softIcon,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
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
                    report.address.isEmpty
                        ? 'No address provided'
                        : report.address,
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
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusPill(status: report.status),
                const SizedBox(height: AppSpacing.sm),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? AppColors.surface : AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
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
