import '../../features/home/domain/models/report_summary.dart';
import 'package:flutter/material.dart';

class MockCitizen {
  static const name = 'Nguyen Minh Anh';
  static const email = 'minh.anh@civichub.vn';
  static const phone = '+84 912 345 678';
}

class MockReports {
  static const summary = ReportSummary(pending: 3, inProgress: 2, resolved: 12);

  static const recent = [
    RecentReport(
      title: 'Street light outage',
      location: 'Ward 5, District 3',
      status: ReportStatus.pending,
      icon: Icons.lightbulb_outline,
    ),
    RecentReport(
      title: 'Sidewalk repair request',
      location: 'Nguyen Trai Street',
      status: ReportStatus.inProgress,
      icon: Icons.construction_outlined,
    ),
    RecentReport(
      title: 'Public bin overflow',
      location: 'Central Park Gate A',
      status: ReportStatus.resolved,
      icon: Icons.check_circle_outline,
    ),
  ];
}
