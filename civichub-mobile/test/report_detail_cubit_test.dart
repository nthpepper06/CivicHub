import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/report_detail_cubit.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/report_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Load emits success with report detail', () async {
    final repository = FakeReportsRepository();
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    await cubit.load();

    expect(cubit.state.status, ReportDetailStatus.success);
    expect(cubit.state.report?.id, 12);
    expect(repository.detailCalls.single, 12);
  });

  test('Load reports unauthorized failure', () async {
    final repository = FakeReportsRepository()
      ..detailError = ApiException.unauthorized;
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    await cubit.load();

    expect(cubit.state.status, ReportDetailStatus.failure);
    expect(cubit.state.errorKind, ApiErrorKind.unauthorized);
    expect(cubit.state.isUnauthorized, isTrue);
  });

  test('Report not found maps to empty state', () async {
    final repository = FakeReportsRepository()
      ..detailError = ApiException.notFound.copyWith(
        message: 'Report not found',
      );
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 404,
    );

    await cubit.load();

    expect(cubit.state.status, ReportDetailStatus.empty);
    expect(cubit.state.errorKind, ApiErrorKind.notFound);
    expect(cubit.state.errorMessage, 'Report not found');
  });

  test('Malformed response maps to readable failure', () async {
    final repository = FakeReportsRepository()
      ..detailError = ApiException.invalidResponse;
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    await cubit.load();

    expect(cubit.state.status, ReportDetailStatus.failure);
    expect(cubit.state.errorMessage, contains('could not be read'));
  });

  test('Retry reloads after failure', () async {
    final repository = FakeReportsRepository()
      ..detailError = ApiException.network;
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    await cubit.load();
    repository.detailError = null;
    await cubit.retry();

    expect(cubit.state.status, ReportDetailStatus.success);
    expect(repository.detailCalls, [12, 12]);
  });

  test('Loading state is emitted while request is in flight', () async {
    final completer = Completer<CitizenReportDetail>();
    final repository = FakeReportsRepository()
      ..pendingDetailResponse = completer.future;
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    final loading = cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, ReportDetailStatus.loading);

    completer.complete(sampleReportDetail(id: 12));
    await loading;
    expect(cubit.state.status, ReportDetailStatus.success);
  });

  test('Cancel refreshes detail and emits action success', () async {
    final repository = FakeReportsRepository();
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    await cubit.load();
    await cubit.cancel();

    expect(repository.cancelCalls.single, 12);
    expect(repository.detailCalls, [12, 12]);
    expect(cubit.state.report?.status.name, 'cancelled');
    expect(cubit.state.actionSucceeded, isTrue);
  });

  test('Duplicate cancel is prevented', () async {
    final completer = Completer<CitizenReportDetail>();
    final repository = FakeReportsRepository()
      ..pendingCancelResponse = completer.future;
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );
    await cubit.load();

    final first = cubit.cancel();
    final second = cubit.cancel();
    await Future<void>.delayed(Duration.zero);
    completer.complete(
      sampleReportDetail(id: 12, status: ReportStatus.cancelled),
    );
    await first;
    await second;

    expect(repository.cancelCalls, hasLength(1));
  });

  test('Cancel forbidden failure is exposed', () async {
    final repository = FakeReportsRepository()
      ..cancelError = ApiException.forbidden;
    final cubit = ReportDetailCubit(
      reportsRepository: repository,
      reportId: 12,
    );

    await cubit.load();
    await cubit.cancel();

    expect(cubit.state.actionErrorMessage, ApiException.forbidden.message);
    expect(cubit.state.actionSucceeded, isFalse);
  });
}
