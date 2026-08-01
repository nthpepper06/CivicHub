import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/models/report_summary.dart';

class StaffQueueBuckets {
  const StaffQueueBuckets({
    required this.needsAttention,
    required this.inProgress,
    required this.completed,
  });

  factory StaffQueueBuckets.fromReports(List<CitizenReportSummary> reports) {
    final needsAttention = <CitizenReportSummary>[];
    final inProgress = <CitizenReportSummary>[];
    final completed = <CitizenReportSummary>[];

    for (final report in reports) {
      switch (report.status) {
        case ReportStatus.pending:
        case ReportStatus.received:
        case ReportStatus.unknown:
          needsAttention.add(report);
        case ReportStatus.inProgress:
          inProgress.add(report);
        case ReportStatus.resolved:
        case ReportStatus.rejected:
        case ReportStatus.cancelled:
          completed.add(report);
      }
    }

    return StaffQueueBuckets(
      needsAttention: List.unmodifiable(needsAttention),
      inProgress: List.unmodifiable(inProgress),
      completed: List.unmodifiable(completed),
    );
  }

  final List<CitizenReportSummary> needsAttention;
  final List<CitizenReportSummary> inProgress;
  final List<CitizenReportSummary> completed;
}
