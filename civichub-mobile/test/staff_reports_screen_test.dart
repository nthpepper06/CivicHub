import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_reports_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_workspace_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/screens/staff_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  setUp(StaffReportsCubit.resetSessionFiltersForTest);

  testWidgets('staff reports renders professional queue sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final staffRepository = FakeStaffRepository(
      pages: [
        sampleReportsPage(
          content: [
            sampleReport(id: 1, title: 'Pending case'),
            sampleReport(
              id: 2,
              title: 'Active case',
              status: ReportStatus.inProgress,
            ),
            sampleReport(
              id: 3,
              title: 'Completed case',
              status: ReportStatus.resolved,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(_App(staffRepository: staffRepository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Staff work queue'), findsOneWidget);
    expect(find.text('Advanced filters'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('In Progress'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Next report'), findsOneWidget);
    expect(find.text('Oldest pending'), findsOneWidget);
    expect(find.text('Pending case'), findsOneWidget);
    expect(find.text('Active case'), findsOneWidget);
    expect(find.text('Completed case'), findsOneWidget);
  });

  testWidgets('staff reports debounces search input', (tester) async {
    final staffRepository = FakeStaffRepository(
      pages: [
        sampleReportsPage(content: [sampleReport(id: 1)]),
        sampleReportsPage(content: const []),
      ],
    );

    await tester.pumpWidget(_App(staffRepository: staffRepository));
    await tester.pumpAndSettle();
    expect(staffRepository.assignedCalls, hasLength(1));

    await tester.enterText(find.byType(TextField).first, 'drain');
    await tester.pump(const Duration(milliseconds: 349));
    expect(staffRepository.assignedCalls, hasLength(1));

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(staffRepository.assignedCalls, hasLength(2));
    expect(staffRepository.assignedCalls.last.search, 'drain');
  });
}

class _App extends StatelessWidget {
  const _App({required this.staffRepository});

  final FakeStaffRepository staffRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StaffRepository>.value(value: staffRepository),
        RepositoryProvider<ReportsRepository>.value(
          value: FakeReportsRepository(),
        ),
        RepositoryProvider<NotificationsRepository>.value(
          value: FakeNotificationsRepository(),
        ),
      ],
      child: BlocProvider(
        create: (_) => StaffWorkspaceCubit(),
        child: const MaterialApp(home: StaffReportsScreen()),
      ),
    );
  }
}
