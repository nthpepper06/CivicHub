import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2328), Color(0xFF3B4148)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandMark(color: AppColors.surface),
                const Spacer(),
                Text(
                  'City services at your fingertips.',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: AppColors.surface),
                ),
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final message = switch (state.status) {
                      AuthStatus.checking => 'Checking your session...',
                      AuthStatus.authenticated => 'Opening your account...',
                      AuthStatus.unauthenticated => 'Redirecting to login...',
                      AuthStatus.unknown => 'Preparing secure session...',
                      AuthStatus.failure =>
                        state.message ?? 'Unable to verify your session.',
                    };
                    final isFailure = state.status == AuthStatus.failure;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isFailure)
                              const Icon(
                                Icons.wifi_off_outlined,
                                color: AppColors.surface,
                                size: 22,
                              )
                            else
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.surface,
                                ),
                              ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                message,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.surface),
                              ),
                            ),
                          ],
                        ),
                        if (isFailure) ...[
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: 140,
                            child: OutlinedButton(
                              onPressed: () {
                                context.read<AuthCubit>().bootstrap();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.surface,
                                side: const BorderSide(
                                  color: AppColors.surface,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: const Icon(
            Icons.account_balance_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'CivicHub',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}
