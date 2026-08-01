import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
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
import '../../../reports/domain/models/report_status.dart';
import '../../domain/models/staff_dashboard_summary.dart';
import '../../domain/repositories/staff_repository.dart';
import '../cubit/staff_home_cubit.dart';
import '../cubit/staff_home_state.dart';
import '../cubit/staff_workspace_cubit.dart';
import '../widgets/staff_meta_chip.dart';
import '../widgets/staff_section_header.dart';

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
                                if (state.isInitialLoading)
                                  const AppLoading(
                                    message: 'Loading workspace',
                                    rows: 3,
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
                                  _OperationsHero(
                                    user: user,
                                    summary: state.summary,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _SummaryGrid(
                                    summary: state.summary,
                                    unreadCount: state.unreadCount,
                                    recentReports: state.recentReports,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _TodaysPriority(reports: state.recentReports),
                                  const SizedBox(height: AppSpacing.lg),
                                  _RecentActivity(
                                    reports: state.recentReports,
                                    hasSummary: state.summary != null,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _StaffModules(unreadCount: state.unreadCount),
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

class _OperationsHero extends StatelessWidget {
  const _OperationsHero({required this.user, required this.summary});

  final CitizenProfile? user;
  final StaffDashboardSummary? summary;

  @override
  Widget build(BuildContext context) {
    final department = user?.departmentName?.trim();
    final name = user?.fullName.trim();
    final active = summary?.activeReports ?? 0;
    return PremiumSurface(
      gradient: AppGradients.cityHero,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                department == null || department.isEmpty
                    ? 'Department workspace'
                    : department,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name == null || name.isEmpty ? 'Staff dashboard' : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _todayLabel(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
          final workload = _HeroWorkload(active: active);
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.lg),
                workload,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(width: 260, child: workload),
            ],
          );
        },
      ),
    );
  }
}

class _HeroWorkload extends StatelessWidget {
  const _HeroWorkload({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.work_outline, color: AppColors.surface),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$active',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Current workload',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.surface.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
    required this.unreadCount,
    required this.recentReports,
  });

  final StaffDashboardSummary? summary;
  final int unreadCount;
  final List<CitizenReportSummary> recentReports;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        'Assigned',
        summary?.totalAssigned ?? 0,
        Icons.assignment_outlined,
        AppColors.primary,
        'Department total',
      ),
      _Metric(
        'In Progress',
        summary?.inProgressReports ?? 0,
        Icons.construction_outlined,
        AppColors.warning,
        'Open work',
      ),
      _Metric(
        'Resolved Today',
        _resolvedToday(recentReports),
        Icons.verified_outlined,
        AppColors.success,
        'Loaded recent',
      ),
      _Metric(
        'Unread',
        unreadCount,
        Icons.notifications_active_outlined,
        AppColors.violet,
        'Notifications',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780
            ? 4
            : constraints.maxWidth >= 430
            ? 2
            : 1;
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
  const _Metric(this.label, this.value, this.icon, this.color, this.caption);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String caption;
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(metric.icon, color: metric.color),
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
                Text(
                  metric.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        final modules = [
          _ModuleCard(
            title: 'Assigned Reports',
            subtitle: 'Review and progress department cases',
            icon: Icons.assignment_ind_outlined,
            color: AppColors.primary,
            onTap: () => context.go(AppRoutes.staffReports),
          ),
          _ModuleCard(
            title: 'Notifications',
            subtitle: unreadCount > 0 ? '$unreadCount unread' : 'All caught up',
            icon: Icons.notifications_none_outlined,
            color: AppColors.violet,
            onTap: () => context.go(AppRoutes.staffNotifications),
          ),
          _ModuleCard(
            title: 'Profile',
            subtitle: 'Staff account and department identity',
            icon: Icons.account_circle_outlined,
            color: AppColors.cyan,
            onTap: () => context.go(AppRoutes.staffProfile),
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: 132,
              ),
              itemBuilder: (context, index) => modules[index],
            ),
          ],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _TodaysPriority extends StatelessWidget {
  const _TodaysPriority({required this.reports});

  final List<CitizenReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    final priority = _priorityReport(reports);
    if (priority == null) {
      return AppEmpty(
        title: 'No priority case in loaded reports',
        message: 'Pending or received reports will be highlighted here.',
        icon: Icons.low_priority_outlined,
        actionLabel: 'View assigned reports',
        onAction: () => context.go(AppRoutes.staffReports),
      );
    }
    return PremiumSurface(
      onTap: () => context.push(AppRoutes.staffReportDetailPath(priority.id)),
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.warning.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.priority_high_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Priority",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  priority.title.isEmpty ? 'Untitled report' : priority.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StaffMetaChip(
                      icon: Icons.schedule_outlined,
                      label: _date(priority.createdAt),
                      maxWidth: 150,
                    ),
                    StaffMetaChip(
                      icon: Icons.category_outlined,
                      label: priority.categoryName ?? 'Uncategorized',
                      maxWidth: 150,
                    ),
                    if (priority.address.trim().isNotEmpty)
                      StaffMetaChip(
                        icon: Icons.place_outlined,
                        label: priority.address.trim(),
                        maxWidth: 150,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.reports, required this.hasSummary});

  final List<CitizenReportSummary> reports;
  final bool hasSummary;

  @override
  Widget build(BuildContext context) {
    if (!hasSummary) {
      return const SizedBox.shrink();
    }
    if (reports.isEmpty) {
      return const AppEmpty(
        title: 'No recent activity',
        message: 'Recently updated department reports will appear here.',
        icon: Icons.history_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StaffSectionHeader(
          title: 'Recent activity',
          icon: Icons.history_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < reports.length; index++) ...[
                _ActivityRow(report: reports[index]),
                if (index != reports.length - 1)
                  const Divider(height: 1, color: AppColors.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.report});

  final CitizenReportSummary report;

  @override
  Widget build(BuildContext context) {
    final color = statusColorFor(report.status.apiValue);
    return InkWell(
      onTap: () => context.push(AppRoutes.staffReportDetailPath(report.id)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_activityIcon(report.status), color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activityTitle(report),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    report.title.isEmpty ? 'Untitled report' : report.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StaffMetaChip(
                        icon: Icons.update_outlined,
                        label: _date(report.updatedAt ?? report.createdAt),
                        maxWidth: 150,
                      ),
                      StaffMetaChip(
                        icon: Icons.person_outline,
                        label: report.citizenName ?? 'Citizen unavailable',
                        maxWidth: 150,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

CitizenReportSummary? _priorityReport(List<CitizenReportSummary> reports) {
  final pending =
      reports.where((report) => report.status == ReportStatus.pending).toList()
        ..sort(_oldestFirst);
  if (pending.isNotEmpty) {
    return pending.first;
  }
  final received =
      reports.where((report) => report.status == ReportStatus.received).toList()
        ..sort(_oldestFirst);
  return received.isEmpty ? null : received.first;
}

int _oldestFirst(CitizenReportSummary a, CitizenReportSummary b) {
  final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return left.compareTo(right);
}

int _resolvedToday(List<CitizenReportSummary> reports) {
  final now = DateTime.now();
  return reports.where((report) {
    final updated = report.updatedAt?.toLocal();
    return report.status == ReportStatus.resolved &&
        updated != null &&
        updated.year == now.year &&
        updated.month == now.month &&
        updated.day == now.day;
  }).length;
}

String _activityTitle(CitizenReportSummary report) {
  return switch (report.status) {
    ReportStatus.resolved => 'Completed report',
    ReportStatus.rejected || ReportStatus.cancelled => 'Closed report',
    ReportStatus.inProgress => 'Status moved to in progress',
    ReportStatus.received => 'Report received',
    ReportStatus.pending => 'Assigned report pending review',
    ReportStatus.unknown => 'Report updated',
  };
}

IconData _activityIcon(ReportStatus status) {
  return switch (status) {
    ReportStatus.resolved => Icons.verified_outlined,
    ReportStatus.rejected => Icons.block_outlined,
    ReportStatus.cancelled => Icons.cancel_outlined,
    ReportStatus.inProgress => Icons.construction_outlined,
    ReportStatus.received => Icons.move_to_inbox_outlined,
    ReportStatus.pending => Icons.pending_actions_outlined,
    ReportStatus.unknown => Icons.help_outline,
  };
}

String _todayLabel(DateTime value) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _date(DateTime? value) {
  if (value == null) {
    return 'Unknown date';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
