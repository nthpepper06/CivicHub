import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsPaginationFooter extends StatelessWidget {
  const ReportsPaginationFooter({super.key, required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppLoading(message: 'Loading more reports'),
      );
    }

    final paginationError = state.paginationErrorMessage;
    if (paginationError != null) {
      return AppError(
        title: 'More reports did not load',
        message: paginationError,
        onRetry: context.read<ReportsCubit>().loadMore,
      );
    }

    if (state.reports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      state.hasReachedEnd
          ? '${state.totalElements} reports'
          : 'Showing ${state.reports.length} of ${state.totalElements}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
