import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_content.dart';

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
                      child: ProfileContent(
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

extension on Widget {
  Widget asSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: this),
    );
  }
}
