import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
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
      body: SafeArea(
        child: BlocConsumer<NotificationsCubit, NotificationsState>(
          listenWhen: (previous, current) =>
              previous.markErrorMessage != current.markErrorMessage &&
              current.markErrorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.markErrorMessage!)));
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
                    sliver: SliverToBoxAdapter(child: _Header(state: state)),
                  ),
                  if (state.isInitialLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoading(message: 'Loading notifications'),
                    )
                  else if (state.status == NotificationsStatus.failure &&
                      state.notifications.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppError(
                          title: 'Unable to load notifications',
                          message:
                              state.errorMessage ?? 'Please try again later.',
                          onRetry: context.read<NotificationsCubit>().retry,
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
                      sliver: SliverList.separated(
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return _NotificationTile(
                            notification: notification,
                            isMarking: state.markingIds.contains(
                              notification.id,
                            ),
                          );
                        },
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (state.unreadCount > 0) _UnreadBadge(count: state.unreadCount),
      ],
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
    return Material(
      color: isUnread
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: isMarking
            ? null
            : () async {
                await context.read<NotificationsCubit>().markAsRead(
                  notification,
                );
                if (!context.mounted || !canOpenReport) {
                  return;
                }
                await context.push(AppRoutes.reportDetailPath(reportId));
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusDot(isUnread: isUnread),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.primary),
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
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isUnread});

  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        label: isUnread ? 'Unread' : 'Read',
        child: Icon(
          isUnread ? Icons.circle : Icons.check_circle_outline,
          size: isUnread ? 12 : 18,
          color: isUnread ? AppColors.primary : AppColors.muted,
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
