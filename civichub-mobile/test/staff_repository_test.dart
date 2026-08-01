import 'package:civichub_mobile/features/reports/data/models/report_detail_response.dart';
import 'package:civichub_mobile/features/reports/data/models/report_summary_response.dart';
import 'package:civichub_mobile/features/reports/data/models/reports_page_response.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:civichub_mobile/features/staff/data/models/staff_dashboard_summary_response.dart';
import 'package:civichub_mobile/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'StaffRepository updates assigned report status through data source',
    () async {
      final dataSource = _FakeStaffRemoteDataSource();
      final repository = StaffRepositoryImpl(remoteDataSource: dataSource);

      final report = await repository.updateAssignedReportStatus(
        42,
        ReportStatus.received,
      );

      expect(report.id, 42);
      expect(report.status, ReportStatus.received);
      expect(dataSource.updatedId, 42);
      expect(dataSource.updatedStatus, ReportStatus.received);
    },
  );
}

class _FakeStaffRemoteDataSource implements StaffRemoteDataSource {
  int? updatedId;
  ReportStatus? updatedStatus;

  @override
  Future<StaffDashboardSummaryResponse> getDashboardSummary() {
    throw UnimplementedError();
  }

  @override
  Future<ReportsPageResponse<ReportSummaryResponse>> getRecentReports({
    required int size,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReportsPageResponse<ReportSummaryResponse>> getAssignedReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReportDetailResponse> getAssignedReport(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ReportDetailResponse> updateAssignedReportStatus(
    int id,
    ReportStatus status,
  ) async {
    updatedId = id;
    updatedStatus = status;
    return ReportDetailResponse(
      id: id,
      title: 'Broken sidewalk',
      description: 'Uneven pavement near the bus stop.',
      address: '12 Nguyen Hue',
      status: status,
      categoryId: 7,
      categoryName: 'Roads',
      citizenId: 1,
      citizenName: 'Nguyen Minh Anh',
      images: const [],
      createdAt: DateTime.parse('2026-07-20T10:15:00'),
      updatedAt: DateTime.parse('2026-07-20T10:15:00'),
    );
  }
}
