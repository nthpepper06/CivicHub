import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../auth/domain/models/citizen_profile.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../domain/models/staff_dashboard_summary.dart';
import '../../domain/repositories/staff_repository.dart';
import '../cubit/staff_home_cubit.dart';
import '../cubit/staff_home_state.dart';
import '../cubit/staff_workspace_cubit.dart';
import '../widgets/staff_report_card.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StaffHomeCubit(
        staffRepository: context.read<StaffRepository>(),
        notificationsRepository: context.read<NotificationsRepository>(),
      )..loadInitial(),
      child: const _StaffHomeView(),
    );
  }
}

class _StaffHomeView extends StatelessWidget {
  const _StaffHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Workspace')),
      body: CivicBackground(
        child: SafeArea(
          child: BlocListener<StaffWorkspaceCubit, StaffWorkspaceState>(
            listenWhen: (previous, current) =>
                previous.reportRefreshRevision != current.reportRefreshRevision,
            listener: (context, state) {
              context.read<StaffHomeCubit>().refresh();
            },
            child: BlocBuilder<StaffHomeCubit, StaffHomeState>(
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: context.read<StaffHomeCubit>().refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: AppResponsive(
                            maxWidth: 1040,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StaffHero(user: user),
                                const SizedBox(height: AppSpacing.lg),
                                if (state.isInitialLoading)
                                  const AppLoading(
                                    message: 'Loading staff workspace',
                                    rows: 4,
                                  )
                                else if (state.status ==
                                        StaffHomeStatus.failure &&
                                    state.summary == null)
                                  AppError(
                                    title: 'Unable to load staff workspace',
                                    message:
                                        state.errorMessage ??
                                        'Please try again later.',
                                    onRetry: context
                                        .read<StaffHomeCubit>()
                                        .retry,
                                  )
                                else ...[
                                  _SummaryGrid(
                                    summary: state.summary,
                                    unreadCount: state.unreadCount,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _StaffModules(unreadCount: state.unreadCount),
                                  const SizedBox(height: AppSpacing.lg),
                                  _RecentReports(
                                    reports: state.recentReports,
                                    hasSummary: state.summary != null,
                                  ),
                                  if (state.errorMessage != null) ...[
                                    const SizedBox(height: AppSpacing.lg),
                                    AppError(
                                      title: 'Workspace refresh failed',
                                      message: state.errorMessage!,
                                      onRetry: context
                                          .read<StaffHomeCubit>()
                                          .retry,
                                    ),
                                  ],
                                ],
                              ],
                            ),
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
}

class _StaffHero extends StatelessWidget {
  const _StaffHero({required this.user});

  final CitizenProfile? user;

  @override
  Widget build(BuildContext context) {
    final department = user?.departmentName?.trim();
    return PremiumSurface(
      gradient: AppGradients.profile,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName
                          : 'Staff workspace',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      department == null || department.isEmpty
                          ? 'Department assignment required by backend'
                          : department,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Review department-assigned civic reports and keep residents informed through verified backend workflows.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary, required this.unreadCount});

  final StaffDashboardSummary? summary;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        'Assigned',
        summary?.totalAssigned ?? 0,
        Icons.assignment_outlined,
      ),
      _Metric('Active', summary?.activeReports ?? 0, Icons.pending_actions),
      _Metric(
        'Resolved',
        summary?.resolvedReports ?? 0,
        Icons.verified_outlined,
      ),
      _Metric('Unread', unreadCount, Icons.notifications_active_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _MetricTile(metric: items[index]),
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(metric.icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metric.value}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffModules extends StatelessWidget {
  const _StaffModules({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModuleCard(
            title: 'Assigned Reports',
            subtitle: 'Department-scoped cases',
            icon: Icons.assignment_ind_outlined,
            onTap: () => context.go(AppRoutes.staffReports),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ModuleCard(
            title: 'Notifications',
            subtitle: unreadCount > 0 ? '$unreadCount unread' : 'All caught up',
            icon: Icons.notifications_none_outlined,
            onTap: () => context.go(AppRoutes.staffNotifications),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReports extends StatelessWidget {
  const _RecentReports({required this.reports, required this.hasSummary});

  final List<CitizenReportSummary> reports;
  final bool hasSummary;

  @override
  Widget build(BuildContext context) {
    if (!hasSummary) {
      return const SizedBox.shrink();
    }
    if (reports.isEmpty) {
      return const AppEmpty(
        title: 'No recent assigned reports',
        message: 'Reports assigned to your department will appear here.',
        icon: Icons.assignment_ind_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent assigned reports',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final report in reports) ...[
          StaffReportCard(
            report: report,
            compact: true,
            onTap: () =>
                context.push(AppRoutes.staffReportDetailPath(report.id)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
