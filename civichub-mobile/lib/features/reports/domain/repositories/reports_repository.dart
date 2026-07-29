import '../models/report_status.dart';
import '../models/report_summary.dart';
import '../models/reports_page.dart';

abstract class ReportsRepository {
  Future<ReportsPage<CitizenReportSummary>> getMyReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    String? sortBy,
    String? direction,
  });
}
