import 'package:equatable/equatable.dart';

class StaffDashboardSummary extends Equatable {
  const StaffDashboardSummary({
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

  int get activeReports => pendingReports + receivedReports + inProgressReports;

  @override
  List<Object?> get props => [
    pendingReports,
    receivedReports,
    inProgressReports,
    resolvedReports,
    rejectedReports,
    cancelledReports,
    totalAssigned,
  ];
}
