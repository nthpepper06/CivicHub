import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/domain/models/create_report_request.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/create_report_cubit.dart';
import 'package:civichub_mobile/features/reports/presentation/cubit/create_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Load categories emits ready with dynamic categories', () async {
    final repository = FakeReportsRepository();
    final cubit = CreateReportCubit(reportsRepository: repository);

    await cubit.loadCategories();

    expect(cubit.state.status, CreateReportStatus.ready);
    expect(cubit.state.categories.single.name, 'Roads');
  });

  test('Category failure emits retryable failure state', () async {
    final repository = FakeReportsRepository()
      ..categoryError = ApiException.network;
    final cubit = CreateReportCubit(reportsRepository: repository);

    await cubit.loadCategories();

    expect(cubit.state.status, CreateReportStatus.categoryFailure);
    expect(
      cubit.state.categoryErrorMessage,
      contains('Cannot load categories'),
    );
  });

  test('Selecting category updates state', () async {
    final repository = FakeReportsRepository();
    final cubit = CreateReportCubit(reportsRepository: repository);

    cubit.selectCategory(7);

    expect(cubit.state.selectedCategoryId, 7);
  });

  test('Submit creates report and emits success', () async {
    final repository = FakeReportsRepository();
    final cubit = CreateReportCubit(reportsRepository: repository);

    await cubit.submit(
      const CreateReportRequest(
        title: 'Road hazard',
        description: 'Large pothole',
        address: 'Ward 1',
        categoryId: 7,
        latitude: 10.77,
        longitude: 106.7,
        imageUrls: ['https://example.com/a.jpg'],
      ),
    );

    expect(cubit.state.submitStatus, CreateReportSubmitStatus.success);
    expect(cubit.state.createdReport?.id, 12);
    expect(repository.createRequests.single.imageUrls, [
      'https://example.com/a.jpg',
    ]);
  });

  test('Submit failure maps ApiException', () async {
    final repository = FakeReportsRepository()
      ..createError = ApiException.badRequest.copyWith(
        message: 'title: must not be blank',
      );
    final cubit = CreateReportCubit(reportsRepository: repository);

    await cubit.submit(
      const CreateReportRequest(
        title: '',
        description: 'Large pothole',
        address: 'Ward 1',
        categoryId: 7,
      ),
    );

    expect(cubit.state.submitStatus, CreateReportSubmitStatus.failure);
    expect(cubit.state.submitErrorKind, ApiErrorKind.badRequest);
    expect(cubit.state.submitErrorMessage, 'title: must not be blank');
  });

  test('Duplicate submit is prevented while request is in flight', () async {
    final completer = Completer<CitizenReportDetail>();
    final repository = FakeReportsRepository()
      ..pendingCreateResponse = completer.future;
    final cubit = CreateReportCubit(reportsRepository: repository);
    const request = CreateReportRequest(
      title: 'Road hazard',
      description: 'Large pothole',
      address: 'Ward 1',
      categoryId: 7,
    );

    final first = cubit.submit(request);
    final second = cubit.submit(request);
    await Future<void>.delayed(Duration.zero);
    completer.complete(sampleReportDetail());
    await first;
    await second;

    expect(repository.createRequests, hasLength(1));
    expect(cubit.state.submitStatus, CreateReportSubmitStatus.success);
  });

  test('GPS action reports unavailable without adding dependencies', () async {
    final repository = FakeReportsRepository();
    final cubit = CreateReportCubit(reportsRepository: repository);

    await cubit.useCurrentLocation();

    expect(cubit.state.locationLoading, isFalse);
    expect(cubit.state.locationErrorMessage, contains('GPS is not available'));
  });
}
