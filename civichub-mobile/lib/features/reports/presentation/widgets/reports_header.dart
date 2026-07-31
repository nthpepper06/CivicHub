import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/app_error.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_status.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({
    super.key,
    required this.state,
    required this.searchController,
    required this.onCreateReport,
  });

  final ReportsState state;
  final TextEditingController searchController;
  final VoidCallback onCreateReport;

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
        _CommandHeader(
          sortOption: state.sortOption,
          onCreateReport: onCreateReport,
        ),
        const SizedBox(height: AppSpacing.md),
        _OverviewStrip(state: state),
        const SizedBox(height: AppSpacing.md),
        _FilterWorkspace(state: state, searchController: searchController),
      ],
    );
  }
}

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({
    required this.sortOption,
    required this.onCreateReport,
  });

  final ReportsSortOption sortOption;
  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Manage submitted civic cases, refine results, and follow progress from one workspace.',
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.72),
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _SortMenu(option: sortOption, dark: true),
              FilledButton.icon(
                onPressed: onCreateReport,
                icon: const Icon(Icons.add),
                label: const Text('Create Report'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.lg),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final active = state.reports
        .where(
          (report) =>
              report.status == ReportStatus.pending ||
              report.status == ReportStatus.received ||
              report.status == ReportStatus.inProgress,
        )
        .length;
    final resolved = state.reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final cards = [
          _OverviewMetric(
            label: 'Loaded results',
            value: state.reports.length.toString(),
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
          _OverviewMetric(
            label: 'Active loaded',
            value: active.toString(),
            icon: Icons.pending_actions_outlined,
            color: AppColors.violet,
          ),
          _OverviewMetric(
            label: 'Resolved loaded',
            value: resolved.toString(),
            icon: Icons.verified_outlined,
            color: AppColors.success,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.sm),
                cards[index],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: cards[index]),
            ],
          ],
        );
      },
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterWorkspace extends StatelessWidget {
  const _FilterWorkspace({required this.state, required this.searchController});

  final ReportsState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter workspace',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    searchController.clear();
                    context.read<ReportsCubit>().clearFilters();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              final search = _ReportSearchBar(
                search: state.search,
                controller: searchController,
              );
              final sort = _SortMenu(option: state.sortOption);

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: search),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: sort),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.sm),
                  sort,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusSelector(selectedStatus: state.statusFilter),
          const SizedBox(height: AppSpacing.md),
          if (state.isLoadingCategories)
            _InlineHint(
              icon: Icons.hourglass_empty,
              text: 'Loading categories...',
            )
          else if (state.categories.isNotEmpty)
            _CategorySelector(state: state)
          else if (state.categoryErrorMessage != null)
            AppError(
              title: 'Categories did not load',
              message: state.categoryErrorMessage!,
              onRetry: context.read<ReportsCubit>().loadInitial,
            ),
          const SizedBox(height: AppSpacing.md),
          _ActiveFilterSummary(state: state),
        ],
      ),
    );
  }
}

class _ReportSearchBar extends StatelessWidget {
  const _ReportSearchBar({required this.search, required this.controller});

  final String search;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: context.read<ReportsCubit>().applySearch,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by title or report details',
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
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.option, this.dark = false});

  final ReportsSortOption option;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? AppColors.surface : AppColors.ink;
    final background = dark
        ? AppColors.surface.withValues(alpha: 0.1)
        : AppColors.surfaceAlt;
    return PopupMenuButton<ReportsSortOption>(
      tooltip: 'Sort reports',
      initialValue: option,
      onSelected: context.read<ReportsCubit>().applySort,
      itemBuilder: (context) => [
        for (final value in ReportsSortOption.values)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Expanded(child: Text(value.label)),
                if (option == value) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: dark
                ? AppColors.surface.withValues(alpha: 0.18)
                : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.keyboard_arrow_down, size: 18, color: foreground),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.selectedStatus});

  final ReportStatus? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return _FilterGroup(
      label: 'Status',
      children: [
        _StatusChoice(
          label: 'All',
          selected: selectedStatus == null,
          color: AppColors.primary,
          onTap: () => context.read<ReportsCubit>().applyStatusFilter(null),
        ),
        for (final status in const [
          ReportStatus.pending,
          ReportStatus.received,
          ReportStatus.inProgress,
          ReportStatus.resolved,
          ReportStatus.rejected,
          ReportStatus.cancelled,
        ])
          _StatusChoice(
            label: status.label,
            selected: selectedStatus == status,
            color: statusColorFor(status.apiValue),
            onTap: () => context.read<ReportsCubit>().applyStatusFilter(status),
          ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return _FilterGroup(
      label: 'Category',
      children: [
        _CategoryChoice(
          label: 'All categories',
          selected: state.categoryIdFilter == null,
          color: AppColors.primary,
          onTap: () => context.read<ReportsCubit>().applyCategoryFilter(null),
        ),
        for (final category in state.categories)
          _CategoryChoice(
            category: category,
            label: category.name,
            selected: state.categoryIdFilter == category.id,
            color: CategoryColors.colorFor(category.name),
            onTap: () =>
                context.read<ReportsCubit>().applyCategoryFilter(category.id),
          ),
      ],
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children,
        ),
      ],
    );
  }
}

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WorkspaceChip(
      label: label,
      selected: selected,
      color: color,
      onTap: onTap,
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.category,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final ReportCategory? category;

  @override
  Widget build(BuildContext context) {
    return _WorkspaceChip(
      label: label,
      selected: selected,
      color: color,
      icon: category == null ? Icons.category_outlined : null,
      onTap: onTap,
    );
  }
}

class _WorkspaceChip extends StatelessWidget {
  const _WorkspaceChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.surface : AppColors.inkSoft;
    return Material(
      color: selected ? color : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? color : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasActiveFilters) {
      return const _InlineHint(
        icon: Icons.tune_outlined,
        text: 'Showing all currently loaded report results.',
      );
    }

    final parts = <String>[
      if (state.search.isNotEmpty) 'Search "${state.search}"',
      if (state.statusFilter != null) 'Status ${state.statusFilter!.label}',
      if (state.categoryIdFilter != null)
        'Category ${_categoryName(state.categories, state.categoryIdFilter!)}',
    ];

    return _InlineHint(
      icon: Icons.filter_alt_outlined,
      text: 'Active filters: ${parts.join(', ')}',
      emphasized: true,
    );
  }

  String _categoryName(List<ReportCategory> categories, int id) {
    for (final category in categories) {
      if (category.id == id) {
        return category.name;
      }
    }
    return '#$id';
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primarySoft : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: emphasized
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: emphasized ? AppColors.primary : AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: emphasized ? AppColors.primaryDark : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
