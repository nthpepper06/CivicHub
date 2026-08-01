import '../../domain/models/staff_dashboard_summary.dart';

class StaffDashboardSummaryResponse {
  const StaffDashboardSummaryResponse({
    required this.pendingReports,
    required this.receivedReports,
    required this.inProgressReports,
    required this.resolvedReports,
    required this.rejectedReports,
    required this.cancelledReports,
    required this.totalAssigned,
  });

  final int pendingReports;
  final int receivedReports;
  final int inProgressReports;
  final int resolvedReports;
  final int rejectedReports;
  final int cancelledReports;
  final int totalAssigned;

  factory StaffDashboardSummaryResponse.fromJson(Map<String, dynamic> json) {
    return StaffDashboardSummaryResponse(
      pendingReports: _int(json['pendingReports']),
      receivedReports: _int(json['receivedReports']),
      inProgressReports: _int(json['inProgressReports']),
      resolvedReports: _int(json['resolvedReports']),
      rejectedReports: _int(json['rejectedReports']),
      cancelledReports: _int(json['cancelledReports']),
      totalAssigned: _int(json['totalAssigned']),
    );
  }

  StaffDashboardSummary toDomain() {
    return StaffDashboardSummary(
      pendingReports: pendingReports,
      receivedReports: receivedReports,
      inProgressReports: inProgressReports,
      resolvedReports: resolvedReports,
      rejectedReports: rejectedReports,
      cancelledReports: cancelledReports,
      totalAssigned: totalAssigned,
    );
  }

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
