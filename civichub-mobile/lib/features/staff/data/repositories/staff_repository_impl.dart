import '../../domain/models/staff_dashboard_summary.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../../reports/domain/models/report_detail.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../../reports/domain/models/reports_page.dart';
import '../datasources/staff_remote_data_source.dart';

class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl({required StaffRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final StaffRemoteDataSource _remoteDataSource;

  @override
  Future<StaffDashboardSummary> getDashboardSummary() async {
    final response = await _remoteDataSource.getDashboardSummary();
    return response.toDomain();
  }

  @override
  Future<ReportsPage<CitizenReportSummary>> getRecentReports({
    int size = 5,
  }) async {
    final response = await _remoteDataSource.getRecentReports(size: size);
    return response.toDomain((report) => report.toDomain());
  }

  @override
  Future<ReportsPage<CitizenReportSummary>> getAssignedReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    int? citizenId,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    final response = await _remoteDataSource.getAssignedReports(
      page: page,
      size: size,
      search: search,
      status: status,
      categoryId: categoryId,
      citizenId: citizenId,
      createdFrom: createdFrom,
      createdTo: createdTo,
    );
    return response.toDomain((report) => report.toDomain());
  }

  @override
  Future<CitizenReportDetail> getAssignedReport(int id) async {
    final response = await _remoteDataSource.getAssignedReport(id);
    return response.toDomain();
  }

  @override
  Future<CitizenReportDetail> updateAssignedReportStatus(
    int id,
    ReportStatus status,
  ) async {
    final response = await _remoteDataSource.updateAssignedReportStatus(
      id,
      status,
    );
    return response.toDomain();
  }
}
