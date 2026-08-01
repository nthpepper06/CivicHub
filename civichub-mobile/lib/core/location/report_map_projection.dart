import '../../features/reports/domain/models/report_summary.dart';
import 'location_point.dart';
import 'report_map_point.dart';

class ReportMapProjection {
  const ReportMapProjection._();

  static ReportMapPointResult fromSummaries(
    List<CitizenReportSummary> reports,
  ) {
    final points = <ReportMapPoint>[];
    var excluded = 0;

    for (final report in reports) {
      final latitude = report.latitude;
      final longitude = report.longitude;
      if (latitude == null || longitude == null) {
        excluded++;
        continue;
      }
      final point = LocationPoint(latitude: latitude, longitude: longitude);
      if (!point.isValid) {
        excluded++;
        continue;
      }
      points.add(
        ReportMapPoint(
          reportId: report.id,
          point: point,
          title: report.title,
          statusKey: report.status.apiValue,
          statusLabel: report.status.label,
          category: report.categoryName,
          department: report.departmentName,
          address: report.address,
          createdAt: report.createdAt,
        ),
      );
    }

    return ReportMapPointResult(
      points: List.unmodifiable(points),
      excluded: excluded,
    );
  }
}
