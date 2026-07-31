import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../auth/domain/models/auth_enums.dart';
import '../../../auth/domain/models/citizen_profile.dart';
import '../cubit/profile_cubit.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
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
          ProfileHeader(user: user),
          const SizedBox(height: AppSpacing.lg),
          _ProfileStats(user: user),
          const SizedBox(height: AppSpacing.lg),
          ProfileActionSection(
            isLoggingOut: isLoggingOut,
            onLogout: onLogout,
            errorMessage: errorMessage,
          ),
          const SizedBox(height: AppSpacing.xl),
          ProfileInfoSection(user: user),
        ],
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});

  final CitizenProfile user;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      gradient: AppGradients.profile,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Center(child: ProfileAvatar(user: user, size: 96)),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.fullName.isEmpty ? 'Citizen' : user.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RoleBadge(label: '${_roleLabel(user.role)} account'),
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
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.user});

  final CitizenProfile user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Status',
            value: user.isActive ? 'Active status' : 'Inactive status',
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Phone',
            value: user.phone == null || user.phone!.trim().isEmpty
                ? 'Missing'
                : 'Added',
            icon: Icons.phone_iphone_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileActionSection extends StatelessWidget {
  const ProfileActionSection({
    super.key,
    required this.isLoggingOut,
    required this.onLogout,
    this.errorMessage,
  });

  final bool isLoggingOut;
  final VoidCallback onLogout;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            AppFeedback.show(
              context,
              message: 'Profile updated.',
              type: AppFeedbackType.success,
            );
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
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: const ValueKey('profile_logout_button'),
          label: isLoggingOut ? 'Logging out...' : 'Logout',
          variant: AppButtonVariant.outline,
          onPressed: isLoggingOut ? null : onLogout,
        ),
      ],
    );
  }
}

class ProfileInfoSection extends StatelessWidget {
  const ProfileInfoSection({super.key, required this.user});

  final CitizenProfile user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileSection(
          title: 'Account',
          icon: Icons.manage_accounts_outlined,
          children: [
            ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
              showChevron: false,
            ),
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone ?? 'Not provided',
              showChevron: false,
            ),
            ProfileInfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Role',
              value: _roleLabel(user.role),
              showChevron: false,
            ),
            ProfileInfoRow(
              icon: Icons.shield_outlined,
              label: 'Status',
              value: _statusLabel(user.status, user.isActive),
              showChevron: false,
            ),
          ],
        ),
        if (user.createdAt != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ProfileSection(
            title: 'Security',
            icon: Icons.lock_outline,
            children: [
              ProfileInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: _date(user.createdAt),
                showChevron: false,
              ),
            ],
          ),
        ],
      ],
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.user, required this.size});

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
                  fallback: _AvatarFallback(user: user),
                )
              : _AvatarFallback(user: user),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.user});

  final CitizenProfile user;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
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
