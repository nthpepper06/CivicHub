import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_responsive.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../auth/domain/models/auth_enums.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/citizen_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsCubit(
        notificationsRepository: context.read<NotificationsRepository>(),
      )..loadInitial(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount <= 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(child: _UnreadBadge(count: state.unreadCount)),
              );
            },
          ),
        ],
      ),
      body: CivicBackground(
        child: SafeArea(
          child: BlocConsumer<NotificationsCubit, NotificationsState>(
            listenWhen: (previous, current) =>
                previous.markErrorMessage != current.markErrorMessage &&
                current.markErrorMessage != null,
            listener: (context, state) {
              AppFeedback.show(
                context,
                message: state.markErrorMessage!,
                type: AppFeedbackType.error,
              );
            },
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: context.read<NotificationsCubit>().refresh,
                child: CustomScrollView(
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
                        child: AppResponsive(child: _Header(state: state)),
                      ),
                    ),
                    if (state.isInitialLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: AppResponsive(
                            child: AppLoading(
                              message: 'Loading notifications',
                              rows: 4,
                              showAvatar: true,
                            ),
                          ),
                        ),
                      )
                    else if (state.status == NotificationsStatus.failure &&
                        state.notifications.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: AppResponsive(
                            child: AppError(
                              title: 'Unable to load notifications',
                              message:
                                  state.errorMessage ??
                                  'Please try again later.',
                              onRetry: context.read<NotificationsCubit>().retry,
                            ),
                          ),
                        ),
                      )
                    else if (state.notifications.isEmpty)
                      const AppEmpty(
                        title: 'No notifications yet',
                        message:
                            'Updates about your reports will appear here when there is something new.',
                        icon: Icons.notifications_none_outlined,
                      ).asSliver()
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AppResponsive(
                            child: _NotificationGroups(
                              notifications: state.notifications,
                              markingIds: state.markingIds,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          state.notifications.isEmpty
                              ? ''
                              : '${state.notifications.length} notifications',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
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

class _NotificationGroups extends StatelessWidget {
  const _NotificationGroups({
    required this.notifications,
    required this.markingIds,
  });

  final List<CitizenNotification> notifications;
  final Set<int> markingIds;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<CitizenNotification>>{};
    for (final notification in notifications) {
      grouped.putIfAbsent(_groupLabel(notification.createdAt), () => []);
      grouped[_groupLabel(notification.createdAt)]!.add(notification);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped.entries) ...[
          _InboxGroupHeader(label: entry.key, count: entry.value.length),
          const SizedBox(height: AppSpacing.sm),
          for (final notification in entry.value) ...[
            _NotificationTile(
              notification: notification,
              isMarking: markingIds.contains(notification.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  String _groupLabel(DateTime? value) {
    if (value == null) {
      return 'Earlier';
    }
    final now = DateTime.now();
    final local = value.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final delta = today.difference(day).inDays;
    if (delta == 0) {
      return 'Today';
    }
    if (delta == 1) {
      return 'Yesterday';
    }
    return 'Earlier';
  }
}

class _InboxGroupHeader extends StatelessWidget {
  const _InboxGroupHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: AppSpacing.md),
            child: Divider(color: AppColors.line),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: AppGradients.surfaceGlow,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.action,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.inbox_outlined, color: AppColors.surface),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Important updates from your civic reports.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (state.unreadCount > 0) _UnreadBadge(count: state.unreadCount),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count unread notifications',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            count > 99 ? '99+' : '$count unread',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isMarking,
  });

  final CitizenNotification notification;
  final bool isMarking;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final reportId = notification.reportId;
    final canOpenReport = reportId != null && reportId > 0;
    final accent = NotificationColors.colorFor(notification.type.apiValue);
    return PremiumSurface(
      onTap: isMarking
          ? null
          : () async {
              await context.read<NotificationsCubit>().markAsRead(notification);
              if (!context.mounted || !canOpenReport) {
                return;
              }
              UserRole? role;
              try {
                role = context.read<AuthCubit>().state.user?.role;
              } catch (_) {
                role = null;
              }
              final route = role == UserRole.staff
                  ? AppRoutes.staffReportDetailPath(reportId)
                  : AppRoutes.reportDetailPath(reportId);
              await context.push(route);
            },
      borderColor: isUnread ? accent.withValues(alpha: 0.28) : AppColors.line,
      padding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        decoration: BoxDecoration(
          color: isUnread ? accent.withValues(alpha: 0.06) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 4,
              height: 92,
              decoration: BoxDecoration(
                color: isUnread ? accent : AppColors.lineStrong,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.md),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationIcon(
                      apiValue: notification.type.apiValue,
                      isUnread: isUnread,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title.isEmpty
                                ? notification.type.label
                                : notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isUnread ? FontWeight.w800 : null,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            notification.message.isEmpty
                                ? 'No additional details provided.'
                                : notification.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.78),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _date(notification.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                              Text(
                                notification.type.label,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(color: accent),
                              ),
                              if (canOpenReport)
                                Text(
                                  'Report #$reportId',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isMarking)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (canOpenReport)
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) {
      return 'Unknown time';
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.apiValue, required this.isUnread});

  final String apiValue;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final color = NotificationColors.colorFor(apiValue);
    return Semantics(
      label: isUnread ? 'Unread notification' : 'Read notification',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isUnread ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(NotificationColors.iconFor(apiValue), color: color),
            if (isUnread)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.circle, size: 8, color: AppColors.primary),
              ),
          ],
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
