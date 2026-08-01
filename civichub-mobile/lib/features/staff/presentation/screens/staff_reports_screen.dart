import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../cubit/staff_reports_cubit.dart';
import '../cubit/staff_reports_state.dart';
import '../widgets/staff_report_card.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Reports')),
      body: CivicBackground(
        child: SafeArea(
          child: BlocBuilder<StaffReportsCubit, StaffReportsState>(
            builder: (context, state) {
              if (_searchController.text != state.search) {
                _searchController.text = state.search;
                _searchController.selection = TextSelection.collapsed(
                  offset: _searchController.text.length,
                );
              }
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
                          maxWidth: 1100,
                          child: _FilterPanel(
                            state: state,
                            searchController: _searchController,
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
                              message: 'Loading assigned reports',
                              rows: 4,
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
                              onRetry: context.read<StaffReportsCubit>().retry,
                            ),
                          ),
                        ),
                      )
                    else if (state.reports.isEmpty)
                      AppEmpty(
                        title: state.hasActiveFilters
                            ? 'No matching assigned reports'
                            : 'No assigned reports',
                        message: state.hasActiveFilters
                            ? 'Adjust filters to review more department cases.'
                            : 'Reports assigned to your department will appear here.',
                        icon: Icons.assignment_ind_outlined,
                      ).asSliver()
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AppResponsive(
                            maxWidth: 1100,
                            child: _ReportCollection(state: state),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: AppResponsive(
                          maxWidth: 1100,
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
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.state, required this.searchController});

  final StaffReportsState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Department queue',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    searchController.clear();
                    context.read<StaffReportsCubit>().clearFilters();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reports shown here are scoped by the backend to your assigned department.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: searchController,
            onSubmitted: context.read<StaffReportsCubit>().applySearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search assigned reports',
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
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected});

  final ReportStatus? selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FilterChipButton(
          label: 'All',
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
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
            onTap: () => context.read<StaffReportsCubit>().applyCategoryFilter(
              category.id,
            ),
          ),
      ],
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
    return ChoiceChip(
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
    );
  }
}

class _ReportCollection extends StatelessWidget {
  const _ReportCollection({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 860;
        if (useGrid) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.reports.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 210,
            ),
            itemBuilder: (context, index) => StaffReportCard(
              report: state.reports[index],
              onTap: () => context.push(
                AppRoutes.staffReportDetailPath(state.reports[index].id),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => StaffReportCard(
            report: state.reports[index],
            onTap: () => context.push(
              AppRoutes.staffReportDetailPath(state.reports[index].id),
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final StaffReportsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const AppLoading(message: 'Loading more reports', rows: 1);
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

extension on Widget {
  Widget asSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: this),
    );
  }
}
