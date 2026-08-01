import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_enums.dart';
import 'package:civichub_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:civichub_mobile/features/staff/presentation/cubit/staff_workspace_cubit.dart';
import 'package:civichub_mobile/features/staff/presentation/screens/staff_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('staff dashboard renders operations sections from real data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final staffRepository = FakeStaffRepository()
      ..recentReportsPage = sampleReportsPage(
        content: [
          sampleReport(
            id: 11,
            title: 'Old pending drainage case',
            status: ReportStatus.pending,
            createdAt: DateTime.parse('2026-07-18T09:00:00'),
          ),
          sampleReport(
            id: 12,
            title: 'New pending street light case',
            status: ReportStatus.pending,
            createdAt: DateTime.parse('2026-07-20T09:00:00'),
          ),
          sampleReport(
            id: 13,
            title: 'Completed pavement case',
            status: ReportStatus.resolved,
            updatedAt: now,
          ),
        ],
      );
    final notificationsRepository = FakeNotificationsRepository(unreadCount: 4);

    await tester.pumpWidget(
      _App(
        staffRepository: staffRepository,
        notificationsRepository: notificationsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Public Works'), findsOneWidget);
    expect(find.text('Nguyen Minh Anh'), findsWidgets);
    expect(find.text('Current workload'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Resolved Today'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text("Today's Priority"), findsOneWidget);
    expect(find.text('Old pending drainage case'), findsWidgets);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Completed report'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  for (final viewport in const [
    Size(390, 844),
    Size(768, 1024),
    Size(1024, 768),
    Size(1440, 900),
  ]) {
    testWidgets('staff dashboard is overflow-safe at $viewport', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepository = FakeStaffRepository()
        ..recentReportsPage = sampleReportsPage(
          content: [
            sampleReport(id: 21, title: 'Queued staff case'),
            sampleReport(
              id: 22,
              title: 'Resolved staff case',
              status: ReportStatus.resolved,
              updatedAt: DateTime.now(),
            ),
          ],
        );

      await tester.pumpWidget(
        _App(
          staffRepository: staffRepository,
          notificationsRepository: FakeNotificationsRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current workload'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _App extends StatelessWidget {
  const _App({
    required this.staffRepository,
    required this.notificationsRepository,
  });

  final FakeStaffRepository staffRepository;
  final FakeNotificationsRepository notificationsRepository;

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: MemoryAuthTokenStorage(),
    );
    final authCubit = AuthCubit(authRepository: authRepository)
      ..setAuthenticated(
        sampleUser(
          role: UserRole.staff,
        ).copyWith(departmentId: 3, departmentName: 'Public Works'),
      );
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<StaffRepository>.value(value: staffRepository),
        RepositoryProvider<NotificationsRepository>.value(
          value: notificationsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider(create: (_) => StaffWorkspaceCubit()),
        ],
        child: const MaterialApp(home: StaffHomeScreen()),
      ),
    );
  }
}
