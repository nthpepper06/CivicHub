import '../../../reports/domain/models/report_detail.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../../reports/domain/models/reports_page.dart';
import '../models/staff_dashboard_summary.dart';

abstract class StaffRepository {
  Future<StaffDashboardSummary> getDashboardSummary();

  Future<ReportsPage<CitizenReportSummary>> getRecentReports({int size = 5});

  Future<ReportsPage<CitizenReportSummary>> getAssignedReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
  });

  Future<CitizenReportDetail> getAssignedReport(int id);
}
