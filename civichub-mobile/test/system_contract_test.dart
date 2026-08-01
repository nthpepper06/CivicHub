import 'package:civichub_mobile/features/notifications/domain/models/notification_type.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report statuses match backend and admin production contract', () {
    expect(
      ReportStatus.values
          .where((status) => status != ReportStatus.unknown)
          .map((status) => status.apiValue),
      [
        'PENDING',
        'RECEIVED',
        'IN_PROGRESS',
        'RESOLVED',
        'REJECTED',
        'CANCELLED',
      ],
    );
  });

  test('notification types match backend production contract', () {
    expect(
      CitizenNotificationType.values
          .where((type) => type != CitizenNotificationType.unknown)
          .map((type) => type.apiValue),
      ['REPORT_ASSIGNED', 'REPORT_STATUS_CHANGED'],
    );
  });
}
