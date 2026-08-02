import '../models/create_report_request.dart';
import '../models/report_category.dart';
import '../models/report_detail.dart';
import '../models/report_image_upload_file.dart';
import '../models/report_status.dart';
import '../models/report_summary.dart';
import '../models/reports_page.dart';
import '../models/uploaded_report_image.dart';

abstract class ReportsRepository {
  Future<List<ReportCategory>> getCategories();

  Future<CitizenReportDetail> createReport(CreateReportRequest request);

  Future<UploadedReportImage> uploadReportImage(ReportImageUploadFile file);

  Future<CitizenReportDetail> getMyReport(int id);

  Future<CitizenReportDetail> updateMyReport(
    int id,
    CreateReportRequest request,
  );

  Future<CitizenReportDetail> cancelMyReport(int id);

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
