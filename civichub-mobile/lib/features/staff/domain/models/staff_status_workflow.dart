import '../../../reports/domain/models/report_status.dart';

class StaffStatusWorkflow {
  const StaffStatusWorkflow._();

  static const Map<ReportStatus, List<ReportStatus>> transitions = {
    ReportStatus.pending: [ReportStatus.received, ReportStatus.rejected],
    ReportStatus.received: [ReportStatus.inProgress, ReportStatus.rejected],
    ReportStatus.inProgress: [ReportStatus.resolved, ReportStatus.rejected],
  };

  static List<ReportStatus> actionsFor(ReportStatus status) {
    return transitions[status] ?? const [];
  }
}
