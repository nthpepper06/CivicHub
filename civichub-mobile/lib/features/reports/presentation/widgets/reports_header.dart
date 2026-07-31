import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error.dart';
import '../../domain/models/report_status.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({
    super.key,
    required this.state,
    required this.searchController,
  });

  final ReportsState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    if (searchController.text != state.search) {
      searchController.text = state.search;
      searchController.selection = TextSelection.collapsed(
        offset: searchController.text.length,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reports',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            _SortPill(option: state.sortOption),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReportSearchBar(search: state.search, controller: searchController),
        const SizedBox(height: AppSpacing.md),
        _StatusFilterBar(selectedStatus: state.statusFilter),
        if (state.isLoadingCategories) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading categories...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ] else if (state.categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _CategoryFilterBar(state: state),
        ] else if (state.categoryErrorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppError(
            title: 'Categories did not load',
            message: state.categoryErrorMessage!,
            onRetry: context.read<ReportsCubit>().loadInitial,
          ),
        ],
      ],
    );
  }
}

class _ReportSearchBar extends StatelessWidget {
  const _ReportSearchBar({required this.search, required this.controller});

  final String search;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        controller: controller,
        onSubmitted: context.read<ReportsCubit>().applySearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search reports',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: search.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    context.read<ReportsCubit>().applySearch('');
                  },
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selectedStatus});

  final ReportStatus? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatusChip(
          label: 'All',
          selected: selectedStatus == null,
          onSelected: () =>
              context.read<ReportsCubit>().applyStatusFilter(null),
        ),
        for (final status in const [
          ReportStatus.pending,
          ReportStatus.received,
          ReportStatus.inProgress,
          ReportStatus.resolved,
          ReportStatus.rejected,
          ReportStatus.cancelled,
        ])
          _StatusChip(
            label: status.label,
            selected: selectedStatus == status,
            onSelected: () =>
                context.read<ReportsCubit>().applyStatusFilter(status),
          ),
      ],
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _CategoryChip(
          label: 'All categories',
          selected: state.categoryIdFilter == null,
          onSelected: () =>
              context.read<ReportsCubit>().applyCategoryFilter(null),
        ),
        for (final category in state.categories)
          _CategoryChip(
            label: category.name,
            selected: state.categoryIdFilter == category.id,
            onSelected: () =>
                context.read<ReportsCubit>().applyCategoryFilter(category.id),
          ),
      ],
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({required this.option});

  final ReportsSortOption option;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softIcon,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          option.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? AppColors.surface : AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? AppColors.surface : AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
    );
  }
}
