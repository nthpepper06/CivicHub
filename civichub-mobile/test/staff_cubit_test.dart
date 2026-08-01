import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/staff/domain/models/staff_status_workflow.dart';
import 'package:civichub_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_home_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_home_state.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_report_detail_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_report_detail_state.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_reports_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_reports_state.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_workspace_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  group('StaffStatusWorkflow', () {
    test('matches backend staff transition table', () {
      expect(StaffStatusWorkflow.actionsFor(ReportStatus.pending), [
        ReportStatus.received,
        ReportStatus.rejected,
      ]);
      expect(StaffStatusWorkflow.actionsFor(ReportStatus.received), [
        ReportStatus.inProgress,
        ReportStatus.rejected,
      ]);
      expect(StaffStatusWorkflow.actionsFor(ReportStatus.inProgress), [
        ReportStatus.resolved,
        ReportStatus.rejected,
      ]);
      expect(StaffStatusWorkflow.actionsFor(ReportStatus.resolved), isEmpty);
      expect(StaffStatusWorkflow.actionsFor(ReportStatus.rejected), isEmpty);
      expect(StaffStatusWorkflow.actionsFor(ReportStatus.cancelled), isEmpty);
    });
  });

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

  group('StaffWorkspaceCubit', () {
    test('increments report refresh revision after workflow update', () {
      final cubit = StaffWorkspaceCubit();

      cubit.reportWorkflowUpdated();

      expect(cubit.state.reportRefreshRevision, 1);
    });
  });

  group('StaffReportsCubit', () {
    late StaffRepository staffRepository;
    late ReportsRepository reportsRepository;

    setUp(() {
      StaffReportsCubit.resetSessionFiltersForTest();
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
      await cubit.applyCitizenFilter('42');
      final from = DateTime.parse('2026-07-01T00:00:00');
      final to = DateTime.parse('2026-07-31T23:59:59');
      await cubit.applyDateRange(from, to);

      final lastCall = fakeStaff.assignedCalls.last;
      expect(lastCall.search, 'sidewalk');
      expect(lastCall.status, ReportStatus.inProgress);
      expect(lastCall.categoryId, 7);
      expect(lastCall.citizenId, 42);
      expect(lastCall.createdFrom, from);
      expect(lastCall.createdTo, to);
    });

    test('persists selected filters for the app session', () async {
      final firstCubit = StaffReportsCubit(
        staffRepository: staffRepository,
        reportsRepository: reportsRepository,
      );

      await firstCubit.applySearch('water');
      await firstCubit.applyStatusFilter(ReportStatus.received);
      await firstCubit.applyCitizenFilter('9');

      final secondCubit = StaffReportsCubit(
        staffRepository: FakeStaffRepository(),
        reportsRepository: FakeReportsRepository(),
      );

      expect(secondCubit.state.search, 'water');
      expect(secondCubit.state.statusFilter, ReportStatus.received);
      expect(secondCubit.state.citizenIdFilter, 9);
    });

    test('exposes queue navigation helpers from loaded reports', () async {
      staffRepository = FakeStaffRepository(
        pages: [
          sampleReportsPage(
            content: [
              sampleReport(
                id: 1,
                status: ReportStatus.pending,
                createdAt: DateTime.parse('2026-07-20T10:00:00'),
              ),
              sampleReport(
                id: 2,
                status: ReportStatus.pending,
                createdAt: DateTime.parse('2026-07-19T10:00:00'),
              ),
              sampleReport(id: 3, status: ReportStatus.inProgress),
            ],
          ),
        ],
      );
      final cubit = StaffReportsCubit(
        staffRepository: staffRepository,
        reportsRepository: reportsRepository,
      );

      await cubit.loadInitial();

      expect(cubit.nextReportAfter(1)?.id, 2);
      expect(cubit.previousReportBefore(2)?.id, 1);
      expect(cubit.oldestPending?.id, 2);
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

    test('updates status and exposes success message', () async {
      final staffRepository = FakeStaffRepository();
      final cubit = StaffReportDetailCubit(
        staffRepository: staffRepository,
        reportId: 42,
      );
      await cubit.load();

      await cubit.updateStatus(ReportStatus.received);

      expect(cubit.state.report?.status, ReportStatus.received);
      expect(cubit.state.updateSuccessMessage, 'Report marked as received.');
      expect(
        staffRepository.statusUpdateCalls.single.status,
        ReportStatus.received,
      );
    });

    test('rejects unavailable transition without API call', () async {
      final staffRepository = FakeStaffRepository();
      final cubit = StaffReportDetailCubit(
        staffRepository: staffRepository,
        reportId: 42,
      );
      await cubit.load();

      await cubit.updateStatus(ReportStatus.resolved);

      expect(staffRepository.statusUpdateCalls, isEmpty);
      expect(cubit.state.report?.status, ReportStatus.pending);
    });

    test('prevents duplicate status submissions', () async {
      final completer = Completer<CitizenReportDetail>();
      final staffRepository = FakeStaffRepository()
        ..pendingUpdateStatusResponse = completer.future;
      final cubit = StaffReportDetailCubit(
        staffRepository: staffRepository,
        reportId: 42,
      );
      await cubit.load();

      final first = cubit.updateStatus(ReportStatus.received);
      await cubit.updateStatus(ReportStatus.rejected);

      expect(staffRepository.statusUpdateCalls, hasLength(1));
      completer.complete(
        sampleReportDetail(id: 42, status: ReportStatus.received),
      );
      await first;
      expect(cubit.state.report?.status, ReportStatus.received);
    });

    test('reports update failure and keeps current detail', () async {
      final staffRepository = FakeStaffRepository()
        ..updateStatusError = ApiException.conflict;
      final cubit = StaffReportDetailCubit(
        staffRepository: staffRepository,
        reportId: 42,
      );
      await cubit.load();

      await cubit.updateStatus(ReportStatus.received);

      expect(cubit.state.report?.status, ReportStatus.pending);
      expect(cubit.state.updateErrorMessage, ApiException.conflict.message);
      expect(cubit.state.isUpdatingStatus, isFalse);
    });
  });
}
