import 'package:flutter/material.dart';

import '../../../../core/config/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../home/domain/models/report_summary.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ReportStatus? _filter;
  bool _refreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _refreshing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _refreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final reports = MockReports.recent.where((report) {
      final matchesFilter = _filter == null || report.status == _filter;
      final matchesQuery =
          query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.location.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search by title or location',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _StatusChip(
                        label: 'All',
                        selected: _filter == null,
                        onSelected: () => setState(() => _filter = null),
                      ),
                      _StatusChip(
                        label: ReportStatus.pending.label,
                        selected: _filter == ReportStatus.pending,
                        onSelected: () =>
                            setState(() => _filter = ReportStatus.pending),
                      ),
                      _StatusChip(
                        label: ReportStatus.inProgress.label,
                        selected: _filter == ReportStatus.inProgress,
                        onSelected: () =>
                            setState(() => _filter = ReportStatus.inProgress),
                      ),
                      _StatusChip(
                        label: ReportStatus.resolved.label,
                        selected: _filter == ReportStatus.resolved,
                        onSelected: () =>
                            setState(() => _filter = ReportStatus.resolved),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_refreshing)
                    const AppLoading(message: 'Refreshing reports'),
                  if (!_refreshing && reports.isEmpty)
                    const AppEmpty(
                      title: 'No matching reports',
                      message:
                          'Try another filter or search term. This is still mock data.',
                      icon: Icons.inbox_outlined,
                    ),
                  if (!_refreshing && reports.isNotEmpty)
                    ...reports.map(
                      (report) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReportCard(report: report),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Mock states',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppLoading(message: 'Loading reports'),
                  const SizedBox(height: AppSpacing.md),
                  const AppEmpty(
                    title: 'Empty state',
                    message: 'No reports available in this mock state.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppError(
                    title: 'Error state',
                    message: 'Connection is disabled in Sprint 4.1A cleanup.',
                  ),
                ],
              ),
            ),
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final RecentReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softIcon,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(report.icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  report.location,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            report.status.label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
