import 'package:civichub_mobile/features/ai/domain/repositories/ai_assist_repository.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_workspace_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/screens/staff_report_detail_screen.dart';
import 'package:civichub_mobile/features/staff/presentation/workflow/staff_queue_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(StaffQueueSession.clear);

  testWidgets('Staff detail renders report fields and allowed actions', (
    tester,
  ) async {
    final repository = FakeStaffRepository();

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Broken sidewalk'), findsOneWidget);
    expect(find.text('Uneven pavement near the bus stop.'), findsOneWidget);
    expect(find.text('12 Nguyen Hue'), findsWidgets);
    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
    expect(find.text('Mark Received'), findsOneWidget);
    expect(find.text('Mark Rejected'), findsOneWidget);
    expect(find.text('Mark Resolved'), findsNothing);
  });

  testWidgets('Staff detail updates status and shows success feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeStaffRepository();

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Mark Received'));
    final receivedButton = find.widgetWithText(FilledButton, 'Mark Received');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(receivedButton);
    await tester.pumpAndSettle();

    expect(repository.statusUpdateCalls.single.status, ReportStatus.received);
    expect(find.text('Report marked as received.'), findsOneWidget);
    expect(find.text('Received'), findsWidgets);
  });

  testWidgets('terminal resolved state renders completed workflow copy', (
    tester,
  ) async {
    final repository = FakeStaffRepository()
      ..assignedReportDetail = sampleReportDetail(
        status: ReportStatus.resolved,
      );

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Workflow completed'), findsOneWidget);
    expect(
      find.text(
        'This report has reached its final status. No further staff action is required.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('terminal rejected state renders case closed copy', (
    tester,
  ) async {
    final repository = FakeStaffRepository()
      ..assignedReportDetail = sampleReportDetail(
        status: ReportStatus.rejected,
      );

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Case closed'), findsOneWidget);
    expect(
      find.text(
        'This report has been rejected and no further staff action is available.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('terminal cancelled state renders case cancelled copy', (
    tester,
  ) async {
    final repository = FakeStaffRepository()
      ..assignedReportDetail = sampleReportDetail(
        status: ReportStatus.cancelled,
      );

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Case cancelled'), findsOneWidget);
    expect(
      find.text('This report was cancelled and cannot be processed further.'),
      findsOneWidget,
    );
  });

  testWidgets('current-state section does not claim timeline history', (
    tester,
  ) async {
    final repository = FakeStaffRepository();

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Current state'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Latest status from the report record.'), findsOneWidget);
  });

  testWidgets('empty attachments render compact no-attachments state', (
    tester,
  ) async {
    final repository = FakeStaffRepository();

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('No attachments'), findsOneWidget);
  });

  testWidgets('canceling terminal confirmation sends no request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeStaffRepository()
      ..assignedReportDetail = sampleReportDetail(
        status: ReportStatus.inProgress,
      );

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    final resolveButton = find.widgetWithText(FilledButton, 'Mark Resolved');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(resolveButton);
    await tester.pumpAndSettle();

    expect(find.text('Mark this report as resolved?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.statusUpdateCalls, isEmpty);
  });

  testWidgets('confirming terminal confirmation sends exactly one request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeStaffRepository()
      ..assignedReportDetail = sampleReportDetail(
        status: ReportStatus.inProgress,
      );

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    final resolveButton = find.widgetWithText(FilledButton, 'Mark Resolved');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(resolveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Resolution summary'),
      'Issue resolved',
    );
    await tester.tap(find.text('Submit Resolution'));
    await tester.pumpAndSettle();

    expect(repository.statusUpdateCalls, hasLength(1));
    expect(repository.statusUpdateCalls.single.status, ReportStatus.resolved);
    expect(find.text('Report marked as resolved.'), findsOneWidget);
  });

  test(
    'queue session resolves previous and next report navigation targets',
    () {
      StaffQueueSession.remember([
        sampleReport(id: 41, title: 'Previous'),
        sampleReport(id: 42, title: 'Current'),
        sampleReport(id: 43, title: 'Next'),
      ]);

      expect(StaffQueueSession.previous(42)?.id, 41);
      expect(StaffQueueSession.next(42)?.id, 43);
    },
  );

  testWidgets('queue navigation exposes web tooltips', (tester) async {
    StaffQueueSession.remember([
      sampleReport(id: 41, title: 'Previous'),
      sampleReport(id: 42, title: 'Current'),
      sampleReport(id: 43, title: 'Next'),
    ]);
    final repository = FakeStaffRepository();

    await tester.pumpWidget(_App(repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Open the previous report from this queue'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Return to assigned reports with current filters'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Open the next report from this queue'),
      findsOneWidget,
    );
  });

  for (final viewport in const [
    Size(390, 844),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
  ]) {
    testWidgets('staff detail is overflow-safe at $viewport', (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeStaffRepository();

      await tester.pumpWidget(_App(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Broken sidewalk'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _App extends StatelessWidget {
  const _App({required this.repository});

  final FakeStaffRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StaffRepository>.value(value: repository),
        RepositoryProvider<ReportsRepository>.value(
          value: FakeReportsRepository(),
        ),
        RepositoryProvider<AiAssistRepository>.value(
          value: FakeAiAssistRepository(),
        ),
      ],
      child: BlocProvider(
        create: (_) => StaffWorkspaceCubit(),
        child: const MaterialApp(home: StaffReportDetailScreen(reportId: 42)),
      ),
    );
  }
}
