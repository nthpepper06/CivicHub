import 'package:flutter/material.dart';

class ReportSummary {
  const ReportSummary({
    required this.pending,
    required this.inProgress,
    required this.resolved,
  });

  final int pending;
  final int inProgress;
  final int resolved;
}

class RecentReport {
  const RecentReport({
    required this.title,
    required this.location,
    required this.status,
    required this.icon,
  });

  final String title;
  final String location;
  final ReportStatus status;
  final IconData icon;
}

enum ReportStatus { pending, inProgress, resolved }

extension ReportStatusX on ReportStatus {
  String get label {
    return switch (this) {
      ReportStatus.pending => 'Pending',
      ReportStatus.inProgress => 'In Progress',
      ReportStatus.resolved => 'Resolved',
    };
  }
}
