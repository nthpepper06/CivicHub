import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/repositories/reports_repository.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_list.dart';
import '../widgets/reports_pagination_footer.dart';

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
  final TextEditingController _searchController = TextEditingController();

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
          BlocBuilder<ReportsCubit, ReportsState>(
            buildWhen: (previous, current) =>
                previous.sortOption != current.sortOption,
            builder: (context, state) {
              return PopupMenuButton<ReportsSortOption>(
                tooltip: 'Sort reports',
                icon: const Icon(Icons.sort),
                initialValue: state.sortOption,
                onSelected: context.read<ReportsCubit>().applySort,
                itemBuilder: (context) => [
                  for (final option in ReportsSortOption.values)
                    PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Expanded(child: Text(option.label)),
                          if (state.sortOption == option)
                            const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<ReportsCubit>().refresh,
              child: CustomScrollView(
                key: const PageStorageKey('reports_scroll_view'),
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
                    sliver: SliverToBoxAdapter(
                      child: ReportsHeader(
                        state: state,
                        searchController: _searchController,
                      ),
                    ),
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
                    AppEmpty(
                      title: state.hasActiveFilters
                          ? 'No matching reports'
                          : 'No reports yet',
                      message: state.hasActiveFilters
                          ? 'Try adjusting search or filters to see more reports.'
                          : 'Submitted reports will appear here once they are created.',
                      icon: Icons.assignment_outlined,
                    ).asSliver()
                  else
                    ReportsList(reports: state.reports),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: ReportsPaginationFooter(state: state),
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

extension on Widget {
  Widget asSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: this),
    );
  }
}
