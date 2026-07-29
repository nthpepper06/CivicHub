import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_detail.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/models/reports_page.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({required ReportsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ReportsRemoteDataSource _remoteDataSource;

  @override
  Future<List<ReportCategory>> getCategories() async {
    final response = await _remoteDataSource.getCategories();
    return response.map((category) => category.toDomain()).toList();
  }

  @override
  Future<CitizenReportDetail> createReport(CreateReportRequest request) async {
    final response = await _remoteDataSource.createReport(request);
    return response.toDomain();
  }

  @override
  Future<CitizenReportDetail> getMyReport(int id) async {
    final response = await _remoteDataSource.getMyReport(id);
    return response.toDomain();
  }

  @override
  Future<ReportsPage<CitizenReportSummary>> getMyReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    String? sortBy,
    String? direction,
  }) async {
    final response = await _remoteDataSource.getMyReports(
      page: page,
      size: size,
      search: search,
      status: status,
      categoryId: categoryId,
      sortBy: sortBy,
      direction: direction,
    );
    return response.toDomain((report) => report.toDomain());
  }
}
