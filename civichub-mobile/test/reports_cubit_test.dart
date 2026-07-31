import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_summary.dart';
import 'package:civichub_mobile/features/reports/domain/models/reports_page.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/reports_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Initial load emits success with reports', () async {
    final repository = FakeReportsRepository();
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, ReportsStatus.success);
    expect(cubit.state.reports, hasLength(1));
    expect(repository.calls.single.page, 0);
  });

  test('Empty state is represented by success with no reports', () async {
    final repository = FakeReportsRepository(
      pages: [sampleReportsPage(content: const [])],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, ReportsStatus.success);
    expect(cubit.state.reports, isEmpty);
  });

  test('API failure emits failure message', () async {
    final repository = FakeReportsRepository();
    repository.error = ApiException.network;
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, ReportsStatus.failure);
    expect(cubit.state.errorKind, ApiErrorKind.network);
    expect(cubit.state.errorMessage, contains('Cannot load reports'));
  });

  test('Unauthorized failure is preserved for global auth handling', () async {
    final repository = FakeReportsRepository();
    repository.error = ApiException.unauthorized;
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, ReportsStatus.failure);
    expect(cubit.state.errorKind, ApiErrorKind.unauthorized);
  });

  test('Malformed response emits invalid response failure', () async {
    final repository = FakeReportsRepository();
    repository.error = ApiException.invalidResponse;
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.errorKind, ApiErrorKind.invalidResponse);
    expect(cubit.state.errorMessage, contains('could not be read'));
  });

  test('Refresh replaces stale pagination with first page', () async {
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(
          content: [sampleReport(id: 1)],
          page: 0,
          last: false,
          totalElements: 2,
        ),
        sampleReportsPage(
          content: [sampleReport(id: 2)],
          page: 0,
          last: true,
          totalElements: 1,
        ),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    await cubit.refresh();

    expect(cubit.state.reports.single.id, 2);
    expect(cubit.state.page, 0);
    expect(cubit.state.hasReachedEnd, isTrue);
  });

  test('Pagination appends unique reports and ignores duplicates', () async {
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(
          content: [sampleReport(id: 1)],
          page: 0,
          last: false,
          totalElements: 3,
        ),
        sampleReportsPage(
          content: [sampleReport(id: 1), sampleReport(id: 2)],
          page: 1,
          last: true,
          totalElements: 3,
        ),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    await cubit.loadMore();

    expect(cubit.state.reports.map((report) => report.id), [1, 2]);
    expect(cubit.state.hasReachedEnd, isTrue);
  });

  test('Duplicate pagination request is prevented', () async {
    final completer = Completer<ReportsPage<CitizenReportSummary>>();
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(content: [sampleReport(id: 1)], page: 0, last: false),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);
    await cubit.loadInitial();
    repository.pendingResponse = completer.future;

    final first = cubit.loadMore();
    final second = cubit.loadMore();
    await Future<void>.delayed(Duration.zero);
    completer.complete(
      sampleReportsPage(content: [sampleReport(id: 2)], page: 1, last: true),
    );
    await first;
    await second;

    expect(repository.calls.where((call) => call.page == 1), hasLength(1));
  });

  test('Retry loads first page after failure', () async {
    final repository = FakeReportsRepository();
    repository.error = ApiException.server;
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    repository.error = null;
    await cubit.retry();

    expect(cubit.state.status, ReportsStatus.success);
    expect(repository.calls, hasLength(2));
  });

  test('Status filter reloads with verified enum value', () async {
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(content: const []),
        sampleReportsPage(content: const []),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    await cubit.applyStatusFilter(ReportStatus.resolved);

    expect(repository.calls.last.status, ReportStatus.resolved);
    expect(cubit.state.statusFilter, ReportStatus.resolved);
  });

  test('Category filter reloads with backend category id', () async {
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(content: const []),
        sampleReportsPage(content: const []),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    await cubit.applyCategoryFilter(7);

    expect(repository.calls.last.categoryId, 7);
    expect(cubit.state.categoryIdFilter, 7);
  });

  test('Sort reloads with verified backend sort fields', () async {
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(content: const []),
        sampleReportsPage(content: const []),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    await cubit.applySort(ReportsSortOption.titleAsc);

    expect(repository.calls.last.sortBy, 'title');
    expect(repository.calls.last.direction, 'ASC');
    expect(cubit.state.sortOption, ReportsSortOption.titleAsc);
  });

  test('Initial load fetches active categories once', () async {
    final repository = FakeReportsRepository(
      categories: [
        sampleCategory(id: 7, name: 'Roads'),
        sampleCategory(id: 8, name: 'Hidden', isActive: false),
      ],
    );
    final cubit = ReportsCubit(reportsRepository: repository);

    await cubit.loadInitial();
    await cubit.loadInitial();

    expect(cubit.state.categories.map((category) => category.name), ['Roads']);
    expect(repository.categoryCalls, 1);
  });
}
