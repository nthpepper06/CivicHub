import '../../../reports/domain/models/report_summary.dart';

class StaffQueueSession {
  const StaffQueueSession._();

  static List<CitizenReportSummary> _reports = const [];

  static void remember(List<CitizenReportSummary> reports) {
    _reports = List.unmodifiable(reports);
  }

  static void clear() {
    _reports = const [];
  }

  static CitizenReportSummary? previous(int reportId) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index <= 0) {
      return null;
    }
    return _reports[index - 1];
  }

  static CitizenReportSummary? next(int reportId) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1 || index + 1 >= _reports.length) {
      return null;
    }
    return _reports[index + 1];
  }
}
