import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_elevation.dart';
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
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../../reports/presentation/widgets/report_status_chip.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeCubit(reportsRepository: context.read<ReportsRepository>())
            ..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CivicBackground(
        child: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: context.read<HomeCubit>().refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _HomeHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: AppResponsive(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!(state.status == HomeStatus.failure &&
                                  state.recentReports.isEmpty)) ...[
                                _QuickActions(
                                  onCreate: () async {
                                    final created = await context.push<bool>(
                                      AppRoutes.createReport,
                                    );
                                    if (!context.mounted || created != true) {
                                      return;
                                    }
                                    await context.read<HomeCubit>().refresh();
                                  },
                                  onReports: () =>
                                      context.go(AppRoutes.reports),
                                  onNotifications: () =>
                                      context.go(AppRoutes.notifications),
                                  onProfile: () =>
                                      context.go(AppRoutes.profile),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              Text(
                                'My Reports',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (state.isInitialLoading)
                                const AppLoading(
                                  message: 'Loading summary',
                                  rows: 3,
                                  showAvatar: true,
                                )
                              else if (state.status == HomeStatus.failure &&
                                  state.recentReports.isEmpty)
                                AppError(
                                  title: 'Unable to load summary',
                                  message:
                                      state.errorMessage ??
                                      'Please try again later.',
                                  onRetry: context.read<HomeCubit>().retry,
                                )
                              else ...[
                                _SummaryGrid(state: state),
                                const SizedBox(height: AppSpacing.lg),
                                _ReportProgressOverview(state: state),
                                const SizedBox(height: AppSpacing.lg),
                                _SectionHeader(
                                  title: 'Recent Reports',
                                  action: 'View all',
                                  onTap: () => context.go(AppRoutes.reports),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (state.recentReports.isEmpty)
                                  AppEmpty(
                                    title: 'No reports yet',
                                    message:
                                        'Create a report to start tracking city service requests.',
                                    icon: Icons.assignment_outlined,
                                    actionLabel: 'Create Report',
                                    onAction: () =>
                                        context.push(AppRoutes.createReport),
                                  )
                                else
                                  for (final report in state.recentReports)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: _RecentReportTile(report: report),
                                    ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              _NotificationAction(
                                onTap: () =>
                                    context.go(AppRoutes.notifications),
                              ),
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
      decoration: const BoxDecoration(gradient: AppGradients.cityHero),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final greeting = user == null ? 'Citizen' : _firstName(user.fullName);
          return AppResponsive(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: _LocationPill()),
                    const SizedBox(width: AppSpacing.md),
                    IconButton.filledTonal(
                      onPressed: () => context.go(AppRoutes.profile),
                      icon: const Icon(Icons.person_outline),
                      color: AppColors.surface,
                      tooltip: 'Profile',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface.withValues(
                          alpha: 0.14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 560;
                    final copy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $greeting',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.surface),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'A cleaner way to follow city service requests from submission to resolution.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.surface.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                        ),
                      ],
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          copy,
                          const SizedBox(height: AppSpacing.lg),
                          const _SmartCityIllustration(),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: AppSpacing.lg),
                        const _SmartCityIllustration(),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _firstName(String fullName) {
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.surface),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workspace',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.68),
                    ),
                  ),
                  Text(
                    'My civic reports',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.surface),
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

class _SmartCityIllustration extends StatelessWidget {
  const _SmartCityIllustration();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Smart city service dashboard illustration',
      child: SizedBox(
        width: 180,
        height: 110,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: 4,
              right: 18,
              child: _GlowDot(color: AppColors.cyan, size: 42),
            ),
            Positioned(
              top: 24,
              left: 20,
              child: _GlowDot(color: AppColors.violet, size: 28),
            ),
            for (final building in const [
              _BuildingSpec(0, 34, 30),
              _BuildingSpec(34, 58, 44),
              _BuildingSpec(82, 42, 36),
              _BuildingSpec(122, 72, 48),
            ])
              Positioned(
                left: building.left,
                bottom: 0,
                child: Container(
                  width: building.width,
                  height: building.height,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(
                      color: AppColors.surface.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildingSpec {
  const _BuildingSpec(this.left, this.height, this.width);

  final double left;
  final double height;
  final double width;
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.24),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final latest = state.recentReports.isEmpty
        ? null
        : state.recentReports.first;
    final items = [
      _SummaryItem(
        'Total reports',
        state.totalReports.toString(),
        AppColors.primary,
        Icons.assignment_outlined,
      ),
      _SummaryItem(
        'Recent',
        state.recentReports.length.toString(),
        AppColors.warning,
        Icons.history_outlined,
      ),
      _SummaryItem(
        'Latest',
        latest?.status.label ?? '-',
        AppColors.success,
        Icons.insights_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 3 : 1;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: PremiumSurface(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        _IconBubble(icon: item.icon, color: item.color),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: item.color),
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
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.color, this.icon);

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreate,
    required this.onReports,
    required this.onNotifications,
    required this.onProfile,
  });

  final VoidCallback onCreate;
  final VoidCallback onReports;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 520;
        final children = [
          _QuickActionCard(
            title: 'Create Report',
            subtitle: 'Start a new city request',
            icon: Icons.add_circle_outline,
            variant: _QuickActionVariant.create,
            accent: AppColors.cyan,
            gradient: AppGradients.action,
            onTap: onCreate,
          ),
          _QuickActionCard(
            title: 'My Reports',
            subtitle: 'Review active cases',
            icon: Icons.assignment_outlined,
            variant: _QuickActionVariant.reports,
            accent: AppColors.primary,
            onTap: onReports,
          ),
          _QuickActionCard(
            title: 'Notifications',
            subtitle: 'Read civic updates',
            icon: Icons.notifications_outlined,
            variant: _QuickActionVariant.notifications,
            accent: AppColors.warning,
            onTap: onNotifications,
          ),
          _QuickActionCard(
            title: 'Profile',
            subtitle: 'Manage identity',
            icon: Icons.person_outline,
            variant: _QuickActionVariant.profile,
            accent: AppColors.violet,
            onTap: onProfile,
          ),
        ];
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                children[index],
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _ReportProgressOverview extends StatelessWidget {
  const _ReportProgressOverview({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final reports = state.recentReports;
    final counts = <String, int>{
      'Pending': reports
          .where((report) => report.status.apiValue == 'PENDING')
          .length,
      'In Progress': reports
          .where((report) => report.status.apiValue == 'IN_PROGRESS')
          .length,
      'Resolved': reports
          .where((report) => report.status.apiValue == 'RESOLVED')
          .length,
    };
    final total = reports.isEmpty ? 1 : reports.length;
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Progress Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reports.isEmpty
                ? 'Status activity appears after you submit reports.'
                : 'Status mix from your latest ${reports.length} reports.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Row(
              children: [
                for (final entry in counts.entries)
                  Expanded(
                    flex: reports.isEmpty ? 1 : entry.value.clamp(1, total),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 10,
                      color: statusColorFor(
                        entry.key == 'In Progress'
                            ? 'IN_PROGRESS'
                            : entry.key.toUpperCase(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final entry in counts.entries)
                _ProgressLegend(label: entry.key, value: entry.value),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = statusColorFor(
      label == 'In Progress' ? 'IN_PROGRESS' : label.toUpperCase(),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '$label $value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

enum _QuickActionVariant { create, reports, notifications, profile }

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.variant,
    required this.accent,
    required this.onTap,
    this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _QuickActionVariant variant;
  final Color accent;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.gradient != null;
    final radius = BorderRadius.circular(AppRadius.lg);
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 162),
            transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: dark ? null : AppColors.surface,
              gradient: widget.gradient ?? _softGradient(widget.accent),
              borderRadius: radius,
              border: Border.all(
                color: _hovered
                    ? widget.accent.withValues(alpha: 0.34)
                    : AppColors.surface.withValues(alpha: dark ? 0.2 : 0.78),
              ),
              boxShadow: [
                ...(_hovered ? AppElevation.hover : AppElevation.medium),
                BoxShadow(
                  color: widget.accent.withValues(alpha: _hovered ? 0.2 : 0.1),
                  blurRadius: _hovered ? 38 : 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: radius,
                splashColor: widget.accent.withValues(alpha: 0.12),
                highlightColor: widget.accent.withValues(alpha: 0.08),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -32,
                      child: _ModuleGlow(color: widget.accent),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: _AnimatedArrowAccent(
                        color: dark ? AppColors.surface : widget.accent,
                        active: _hovered || _pressed,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _buildContent(context, dark: dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool dark}) {
    return switch (widget.variant) {
      _QuickActionVariant.create => _CreateModuleContent(
        title: widget.title,
        subtitle: widget.subtitle,
        icon: widget.icon,
        accent: widget.accent,
        dark: dark,
      ),
      _QuickActionVariant.reports => _ReportsModuleContent(
        title: widget.title,
        subtitle: widget.subtitle,
        icon: widget.icon,
        accent: widget.accent,
      ),
      _QuickActionVariant.notifications => _NotificationsModuleContent(
        title: widget.title,
        subtitle: widget.subtitle,
        icon: widget.icon,
        accent: widget.accent,
      ),
      _QuickActionVariant.profile => _ProfileModuleContent(
        title: widget.title,
        subtitle: widget.subtitle,
        icon: widget.icon,
        accent: widget.accent,
      ),
    };
  }

  Gradient _softGradient(Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.surface,
        accent.withValues(alpha: 0.08),
        AppColors.surfaceAlt,
      ],
    );
  }

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() {
      _hovered = value;
    });
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }
}

class _CreateModuleContent extends StatelessWidget {
  const _CreateModuleContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.dark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LargeModuleIcon(
              icon: icon,
              color: AppColors.surface,
              background: AppColors.surface.withValues(alpha: 0.18),
              borderColor: AppColors.surface.withValues(alpha: 0.22),
            ),
            const Spacer(),
            _MiniLaunchBadge(color: AppColors.surface, label: 'New'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.surface.withValues(alpha: 0.76),
          ),
        ),
      ],
    );
  }
}

class _ReportsModuleContent extends StatelessWidget {
  const _ReportsModuleContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportStackVisual(icon: icon, color: accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              const _MiniBars(),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsModuleContent extends StatelessWidget {
  const _NotificationsModuleContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LargeModuleIcon(
              icon: icon,
              color: AppColors.warning,
              background: AppColors.warning.withValues(alpha: 0.14),
              borderColor: AppColors.warning.withValues(alpha: 0.2),
            ),
            const Spacer(),
            _SignalDots(color: accent),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _ProfileModuleContent extends StatelessWidget {
  const _ProfileModuleContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniLaunchBadge(color: accent, label: 'ID'),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _ProfileIdentityVisual(icon: icon, color: accent),
      ],
    );
  }
}

class _LargeModuleIcon extends StatelessWidget {
  const _LargeModuleIcon({
    required this.icon,
    required this.color,
    required this.background,
    required this.borderColor,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _ReportStackVisual extends StatelessWidget {
  const _ReportStackVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 88,
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 10,
            child: _StackSheet(width: 48, height: 64, color: color, alpha: 0.1),
          ),
          Positioned(
            left: 6,
            top: 0,
            child: _StackSheet(
              width: 52,
              height: 70,
              color: color,
              alpha: 0.16,
            ),
          ),
          Positioned(
            left: 0,
            top: 18,
            child: _LargeModuleIcon(
              icon: icon,
              color: color,
              background: color.withValues(alpha: 0.12),
              borderColor: color.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackSheet extends StatelessWidget {
  const _StackSheet({
    required this.width,
    required this.height,
    required this.color,
    required this.alpha,
  });

  final double width;
  final double height;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Bar(width: 34, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        _Bar(width: 22, color: AppColors.cyan),
        const SizedBox(width: AppSpacing.xs),
        _Bar(width: 42, color: AppColors.success),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }
}

class _SignalDots extends StatelessWidget {
  const _SignalDots({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 34,
      child: Stack(
        children: [
          for (final dot in const [
            _DotSpec(0, 13, 10),
            _DotSpec(22, 2, 8),
            _DotSpec(42, 18, 12),
          ])
            Positioned(
              left: dot.left,
              top: dot.top,
              child: Container(
                width: dot.size,
                height: dot.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.72),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DotSpec {
  const _DotSpec(this.left, this.top, this.size);

  final double left;
  final double top;
  final double size;
}

class _ProfileIdentityVisual extends StatelessWidget {
  const _ProfileIdentityVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        width: 74,
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.2), AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
      ),
    );
  }
}

class _MiniLaunchBadge extends StatelessWidget {
  const _MiniLaunchBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AnimatedArrowAccent extends StatelessWidget {
  const _AnimatedArrowAccent({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 2,
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.42 : 0.18),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          transform: Matrix4.translationValues(active ? 4 : 0, 0, 0),
          child: Icon(Icons.arrow_forward, size: 18, color: color),
        ),
      ],
    );
  }
}

class _ModuleGlow extends StatelessWidget {
  const _ModuleGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
    );
  }
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

  final CitizenReportSummary report;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      child: Row(
        children: [
          _IconBubble(
            icon: CategoryColors.iconFor(report.categoryName),
            color: CategoryColors.colorFor(report.categoryName),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
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
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: ReportStatusChip(status: report.status, compact: true),
          ),
        ],
      ),
    );
  }
}

class _NotificationAction extends StatelessWidget {
  const _NotificationAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
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
                  'Check city updates and report status alerts.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, this.color = AppColors.primary});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color),
    );
  }
}
