import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_home_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_home_state.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_report_detail_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_report_detail_state.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_reports_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_reports_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  group('StaffHomeCubit', () {
    test('loads summary, recent reports, and unread count', () async {
      final staffRepository = FakeStaffRepository();
      final notificationsRepository = FakeNotificationsRepository(
        unreadCount: 3,
      );
      final cubit = StaffHomeCubit(
        staffRepository: staffRepository,
        notificationsRepository: notificationsRepository,
      );

      await cubit.loadInitial();

      expect(cubit.state.status, StaffHomeStatus.success);
      expect(cubit.state.summary?.totalAssigned, 10);
      expect(cubit.state.recentReports, hasLength(1));
      expect(cubit.state.unreadCount, 3);
      expect(staffRepository.summaryCalls, 1);
      expect(staffRepository.recentCalls, 1);
      expect(notificationsRepository.countCalls, 1);
    });

    test('reports failure and retries', () async {
      final staffRepository = FakeStaffRepository()
        ..summaryError = ApiException.timeout;
      final cubit = StaffHomeCubit(
        staffRepository: staffRepository,
        notificationsRepository: FakeNotificationsRepository(),
      );

      await cubit.loadInitial();

      expect(cubit.state.status, StaffHomeStatus.failure);
      expect(cubit.state.errorKind, ApiErrorKind.timeout);

      staffRepository.summaryError = null;
      await cubit.retry();

      expect(cubit.state.status, StaffHomeStatus.success);
      expect(staffRepository.summaryCalls, 2);
    });
  });

  group('StaffReportsCubit', () {
    late StaffRepository staffRepository;
    late ReportsRepository reportsRepository;

    setUp(() {
      staffRepository = FakeStaffRepository();
      reportsRepository = FakeReportsRepository();
    });

    test('loads assigned reports and categories', () async {
      final cubit = StaffReportsCubit(
        staffRepository: staffRepository,
        reportsRepository: reportsRepository,
      );

      await cubit.loadInitial();

      expect(cubit.state.status, StaffReportsStatus.success);
      expect(cubit.state.reports, hasLength(1));
      expect(cubit.state.categories, hasLength(1));
      expect(
        (staffRepository as FakeStaffRepository).assignedCalls.single.page,
        0,
      );
    });

    test('empty response becomes success with empty reports', () async {
      staffRepository = FakeStaffRepository(
        pages: [sampleReportsPage(content: const [])],
      );
      final cubit = StaffReportsCubit(
        staffRepository: staffRepository,
        reportsRepository: reportsRepository,
      );

      await cubit.loadInitial();

      expect(cubit.state.status, StaffReportsStatus.success);
      expect(cubit.state.reports, isEmpty);
    });

    test('failure can retry', () async {
      final fakeStaff = staffRepository as FakeStaffRepository;
      fakeStaff.assignedError = ApiException.network;
      final cubit = StaffReportsCubit(
        staffRepository: fakeStaff,
        reportsRepository: reportsRepository,
      );

      await cubit.loadInitial();

      expect(cubit.state.status, StaffReportsStatus.failure);
      expect(cubit.state.errorKind, ApiErrorKind.network);

      fakeStaff.assignedError = null;
      await cubit.retry();

      expect(cubit.state.status, StaffReportsStatus.success);
      expect(fakeStaff.assignedCalls, hasLength(2));
    });

    test('applies backend-supported filters', () async {
      final fakeStaff = staffRepository as FakeStaffRepository;
      final cubit = StaffReportsCubit(
        staffRepository: fakeStaff,
        reportsRepository: reportsRepository,
      );

      await cubit.loadInitial();
      await cubit.applySearch('sidewalk');
      await cubit.applyStatusFilter(ReportStatus.inProgress);
      await cubit.applyCategoryFilter(7);

      final lastCall = fakeStaff.assignedCalls.last;
      expect(lastCall.search, 'sidewalk');
      expect(lastCall.status, ReportStatus.inProgress);
      expect(lastCall.categoryId, 7);
    });
  });

  group('StaffReportDetailCubit', () {
    test('loads assigned report detail', () async {
      final staffRepository = FakeStaffRepository();
      final cubit = StaffReportDetailCubit(
        staffRepository: staffRepository,
        reportId: 42,
      );

      await cubit.load();

      expect(cubit.state.status, StaffReportDetailStatus.success);
      expect(cubit.state.report?.id, 42);
      expect((staffRepository).detailCalls.single, 42);
    });
  });
}
