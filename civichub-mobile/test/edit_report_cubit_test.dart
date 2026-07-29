import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/domain/models/create_report_request.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/edit_report_cubit.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/edit_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Load categories emits ready with current category selected', () async {
    final repository = FakeReportsRepository();
    final cubit = EditReportCubit(
      reportsRepository: repository,
      reportId: 12,
      initialReport: sampleReportDetail(id: 12),
    );

    await cubit.loadCategories();

    expect(cubit.state.status, EditReportStatus.ready);
    expect(cubit.state.selectedCategoryId, 7);
  });

  test('Successful update emits success', () async {
    final repository = FakeReportsRepository();
    final cubit = EditReportCubit(
      reportsRepository: repository,
      reportId: 12,
      initialReport: sampleReportDetail(id: 12),
    );

    await cubit.update(
      const CreateReportRequest(
        title: 'Updated title',
        description: 'Updated description',
        address: 'Updated address',
        categoryId: 7,
      ),
    );

    expect(cubit.state.submitStatus, EditReportSubmitStatus.success);
    expect(repository.updateRequests.single.id, 12);
    expect(repository.updateRequests.single.request.title, 'Updated title');
  });

  test('Validation failure from backend is exposed as failure', () async {
    final repository = FakeReportsRepository()
      ..updateError = ApiException.badRequest.copyWith(
        message: 'title: must not be blank',
      );
    final cubit = EditReportCubit(
      reportsRepository: repository,
      reportId: 12,
      initialReport: sampleReportDetail(id: 12),
    );

    await cubit.update(
      const CreateReportRequest(
        title: '',
        description: 'Updated description',
        address: 'Updated address',
        categoryId: 7,
      ),
    );

    expect(cubit.state.submitStatus, EditReportSubmitStatus.failure);
    expect(cubit.state.submitErrorKind, ApiErrorKind.badRequest);
    expect(cubit.state.submitErrorMessage, 'title: must not be blank');
  });

  test('Unauthorized update is mapped', () async {
    final repository = FakeReportsRepository()
      ..updateError = ApiException.unauthorized;
    final cubit = EditReportCubit(
      reportsRepository: repository,
      reportId: 12,
      initialReport: sampleReportDetail(id: 12),
    );

    await cubit.update(
      const CreateReportRequest(
        title: 'Updated title',
        description: 'Updated description',
        address: 'Updated address',
        categoryId: 7,
      ),
    );

    expect(cubit.state.submitErrorKind, ApiErrorKind.unauthorized);
  });

  test('Report not found update is mapped', () async {
    final repository = FakeReportsRepository()
      ..updateError = ApiException.notFound.copyWith(
        message: 'Report not found',
      );
    final cubit = EditReportCubit(
      reportsRepository: repository,
      reportId: 12,
      initialReport: sampleReportDetail(id: 12),
    );

    await cubit.update(
      const CreateReportRequest(
        title: 'Updated title',
        description: 'Updated description',
        address: 'Updated address',
        categoryId: 7,
      ),
    );

    expect(cubit.state.submitErrorKind, ApiErrorKind.notFound);
    expect(cubit.state.submitErrorMessage, 'Report not found');
  });

  test('Duplicate update is prevented', () async {
    final completer = Completer<CitizenReportDetail>();
    final repository = FakeReportsRepository()
      ..pendingUpdateResponse = completer.future;
    final cubit = EditReportCubit(
      reportsRepository: repository,
      reportId: 12,
      initialReport: sampleReportDetail(id: 12),
    );
    const request = CreateReportRequest(
      title: 'Updated title',
      description: 'Updated description',
      address: 'Updated address',
      categoryId: 7,
    );

    final first = cubit.update(request);
    final second = cubit.update(request);
    await Future<void>.delayed(Duration.zero);
    completer.complete(sampleReportDetail(id: 12, title: 'Updated title'));
    await first;
    await second;

    expect(repository.updateRequests, hasLength(1));
    expect(cubit.state.submitStatus, EditReportSubmitStatus.success);
  });
}
