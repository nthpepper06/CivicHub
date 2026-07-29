enum ReportStatus {
  pending('PENDING', 'Pending'),
  received('RECEIVED', 'Received'),
  inProgress('IN_PROGRESS', 'In Progress'),
  resolved('RESOLVED', 'Resolved'),
  rejected('REJECTED', 'Rejected'),
  cancelled('CANCELLED', 'Cancelled'),
  unknown('UNKNOWN', 'Unknown');

  const ReportStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReportStatus fromApiValue(Object? value) {
    if (value is! String) {
      return ReportStatus.unknown;
    }

    for (final status in ReportStatus.values) {
      if (status.apiValue == value) {
        return status;
      }
    }
    return ReportStatus.unknown;
  }
}
