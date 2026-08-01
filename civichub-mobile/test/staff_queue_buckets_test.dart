import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/staff/presentation/workflow/staff_queue_buckets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('groups loaded staff reports into production queue buckets', () {
    final buckets = StaffQueueBuckets.fromReports([
      sampleReport(id: 1, status: ReportStatus.pending),
      sampleReport(id: 2, status: ReportStatus.received),
      sampleReport(id: 3, status: ReportStatus.inProgress),
      sampleReport(id: 4, status: ReportStatus.resolved),
      sampleReport(id: 5, status: ReportStatus.rejected),
      sampleReport(id: 6, status: ReportStatus.cancelled),
      sampleReport(id: 7, status: ReportStatus.unknown),
    ]);

    expect(buckets.needsAttention.map((report) => report.id), [1, 2, 7]);
    expect(buckets.inProgress.map((report) => report.id), [3]);
    expect(buckets.completed.map((report) => report.id), [4, 5, 6]);
  });
}
