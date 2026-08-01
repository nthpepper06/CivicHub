import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/location/report_map_projection.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/spatial_report_map.dart';
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
  bool _mapMode = false;

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

  Future<void> _createReport() async {
    final created = await context.push<bool>(AppRoutes.createReport);
    if (!mounted || created != true) {
      return;
    }
    await context.read<ReportsCubit>().refresh();
    if (!mounted) {
      return;
    }
    AppFeedback.show(
      context,
      message: 'Report submitted.',
      type: AppFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CivicBackground(
        child: SafeArea(
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
                        child: AppResponsive(
                          maxWidth: 1180,
                          child: ReportsHeader(
                            state: state,
                            searchController: _searchController,
                            onCreateReport: _createReport,
                          ),
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
                          child: AppResponsive(
                            maxWidth: 1180,
                            child: AppError(
                              title: 'Unable to load reports',
                              message:
                                  state.errorMessage ??
                                  'Please try again later.',
                              onRetry: context.read<ReportsCubit>().retry,
                            ),
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
                      SliverToBoxAdapter(
                        child: AppResponsive(
                          maxWidth: 1180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ReportsViewModeToggle(
                                mapMode: _mapMode,
                                onChanged: (value) {
                                  setState(() => _mapMode = value);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (_mapMode)
                                SpatialReportMap(
                                  points: ReportMapProjection.fromSummaries(
                                    state.reports,
                                  ).points,
                                  excludedCount:
                                      ReportMapProjection.fromSummaries(
                                        state.reports,
                                      ).excluded,
                                  scopeLabel:
                                      'My reports, current loaded results',
                                  onOpenReport: _openReportFromMap,
                                )
                              else
                                ReportsList(reports: state.reports),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: AppResponsive(
                          maxWidth: 1180,
                          child: ReportsPaginationFooter(state: state),
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

  Future<void> _openReportFromMap(int reportId) async {
    final changed = await context.push<bool>(
      AppRoutes.reportDetailPath(reportId),
    );
    if (!mounted || changed != true) {
      return;
    }
    await context.read<ReportsCubit>().refresh();
  }
}

class _ReportsViewModeToggle extends StatelessWidget {
  const _ReportsViewModeToggle({
    required this.mapMode,
    required this.onChanged,
  });

  final bool mapMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reports view mode',
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.view_agenda_outlined),
            label: Text('List'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.map_outlined),
            label: Text('My Reports Map'),
          ),
        ],
        selected: {mapMode},
        onSelectionChanged: (values) => onChanged(values.first),
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
