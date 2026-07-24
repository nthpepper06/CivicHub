import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/config/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../home/domain/models/report_summary.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader()),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  AppButton(
                    label: 'Create Report',
                    icon: Icons.add_circle_outline,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'My Reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _SummaryGrid(),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    title: 'Recent Reports',
                    action: 'View all',
                    onTap: () => context.go(AppRoutes.reports),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...MockReports.recent.map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RecentReportTile(report: report),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    onTap: () => context.go(AppRoutes.notifications),
                    child: Row(
                      children: [
                        const _IconBubble(icon: Icons.notifications_outlined),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Civic notifications',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'See city updates and report status alerts.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkHeader,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.surface),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current area',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      'CivicHub City',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => GoRouter.of(context).go(AppRoutes.profile),
                icon: const Icon(Icons.person_outline),
                color: AppColors.surface,
                tooltip: 'Profile',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Hello, ${MockCitizen.name.split(' ').last}',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Track public service requests in one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('Pending', MockReports.summary.pending, AppColors.warning),
      _SummaryItem(
        'In Progress',
        MockReports.summary.inProgress,
        AppColors.primary,
      ),
      _SummaryItem('Resolved', MockReports.summary.resolved, AppColors.success),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item == items.last ? 0 : AppSpacing.sm,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value.toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(color: item.color),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  const _RecentReportTile({required this.report});

  final RecentReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          _IconBubble(icon: report.icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  report.location,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            report.status.label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.softIcon,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}
