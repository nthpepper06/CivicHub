import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../auth/domain/models/auth_enums.dart';
import '../../../auth/domain/models/citizen_profile.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        authRepository: context.read<AuthRepository>(),
        authCubit: context.read<AuthCubit>(),
        initialUser: context.read<AuthCubit>().state.user,
      )..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool _isLoggingOut = false;

  Future<void> _confirmLogout(BuildContext context) async {
    if (_isLoggingOut) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to sign in again to use CivicHub.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });
    await context.read<AuthCubit>().logout();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<ProfileCubit>().refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.isInitialLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoading(message: 'Loading profile'),
                    )
                  else if (state.status == ProfileStatus.failure &&
                      state.user == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppError(
                          title: 'Unable to load profile',
                          message:
                              state.errorMessage ?? 'Please try again later.',
                          onRetry: context.read<ProfileCubit>().retry,
                        ),
                      ),
                    )
                  else if (state.user == null)
                    const AppEmpty(
                      title: 'Profile unavailable',
                      message:
                          'Your account details could not be displayed right now.',
                      icon: Icons.person_off_outlined,
                    ).asSliver()
                  else
                    SliverToBoxAdapter(
                      child: _ProfileContent(
                        user: state.user!,
                        isLoggingOut: _isLoggingOut,
                        errorMessage: state.errorMessage,
                        onLogout: () => _confirmLogout(context),
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

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.isLoggingOut,
    required this.onLogout,
    this.errorMessage,
  });

  final CitizenProfile user;
  final bool isLoggingOut;
  final VoidCallback onLogout;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _Avatar(user: user, size: 92)),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.fullName.isEmpty ? 'Citizen' : user.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Edit Profile',
            icon: Icons.edit_outlined,
            onPressed: () async {
              final changed = await context.push<bool>(AppRoutes.editProfile);
              if (!context.mounted || changed != true) {
                return;
              }
              await context.read<ProfileCubit>().refresh();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppError(
              title: 'Profile refresh failed',
              message: errorMessage!,
              onRetry: context.read<ProfileCubit>().retry,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            showChevron: false,
          ),
          _ProfileInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user.phone ?? 'Not provided',
            showChevron: false,
          ),
          _ProfileInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Role',
            value: _roleLabel(user.role),
            showChevron: false,
          ),
          _ProfileInfoRow(
            icon: Icons.shield_outlined,
            label: 'Status',
            value: _statusLabel(user.status, user.isActive),
            showChevron: false,
          ),
          if (user.createdAt != null)
            _ProfileInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Created',
              value: _date(user.createdAt),
              showChevron: false,
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const ValueKey('profile_logout_button'),
            label: isLoggingOut ? 'Logging out...' : 'Logout',
            variant: AppButtonVariant.outline,
            onPressed: isLoggingOut ? null : onLogout,
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.citizen => 'Citizen',
      UserRole.staff => 'Staff',
      UserRole.admin => 'Admin',
    };
  }

  String _statusLabel(UserStatus status, bool isActive) {
    if (!isActive) {
      return 'Inactive';
    }
    return switch (status) {
      UserStatus.active => 'Active',
      UserStatus.inactive => 'Inactive',
      UserStatus.blocked => 'Blocked',
    };
  }

  String _date(DateTime? value) {
    if (value == null) {
      return 'Not available';
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final CitizenProfile user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile avatar',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: size,
          height: size,
          child: user.hasAvatar
              ? AppNetworkImage(
                  url: user.avatar!,
                  fit: BoxFit.cover,
                  logicalWidth: size,
                  logicalHeight: size,
                  fallback: _AvatarFallback(user: user, size: size),
                )
              : _AvatarFallback(user: user, size: size),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.user, required this.size});

  final CitizenProfile user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.softIcon,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, color: AppColors.muted, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (showChevron)
            const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
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
