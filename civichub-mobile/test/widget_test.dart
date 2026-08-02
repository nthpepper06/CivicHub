import 'dart:async';

import 'package:civichub_mobile/app/routing/app_router.dart';
import 'package:civichub_mobile/app/routing/app_routes.dart';
import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/core/storage/auth_token_storage.dart';
import 'package:civichub_mobile/core/widgets/app_network_image.dart';
import 'package:civichub_mobile/core/widgets/location_preview_card.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/domain/models/citizen_profile.dart';
import 'package:civichub_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_state.dart';
import 'package:civichub_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:civichub_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:civichub_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_detail.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/reports/presentation/screens/create_report_screen.dart';
import 'package:civichub_mobile/features/reports/presentation/screens/edit_report_screen.dart';
import 'package:civichub_mobile/features/reports/presentation/screens/report_detail_screen.dart';
import 'package:civichub_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:civichub_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fakes.dart';

extension on CitizenReportDetail {
  CitizenReportDetail copyWithImages(List<ReportImage> images) {
    return CitizenReportDetail(
      id: id,
      title: title,
      description: description,
      address: address,
      status: status,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      categoryName: categoryName,
      departmentId: departmentId,
      departmentName: departmentName,
      citizenId: citizenId,
      citizenName: citizenName,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

Future<
  ({
    AuthCubit authCubit,
    LoginCubit loginCubit,
    AuthTokenStorage storage,
    AuthRepository repository,
  })
>
buildAuthStack({
  Future<LoginResponse>? loginFuture,
  Object? loginError,
  Future<CitizenProfile>? currentUserFuture,
  Object? currentUserError,
}) async {
  final storage = MemoryAuthTokenStorage();
  final remote = FakeAuthRemoteDataSource(
    loginFuture: loginFuture,
    loginError: loginError,
    currentUserFuture: currentUserFuture,
    currentUserError: currentUserError,
  );
  final repository = AuthRepositoryImpl(
    remoteDataSource: remote,
    tokenStorage: storage,
  );
  final authCubit = AuthCubit(authRepository: repository);
  final loginCubit = LoginCubit(
    authRepository: repository,
    authCubit: authCubit,
  );
  return (
    authCubit: authCubit,
    loginCubit: loginCubit,
    storage: storage,
    repository: repository,
  );
}

Future<GoRouter> pumpRouterApp(
  WidgetTester tester, {
  required String initialLocation,
  required FakeReportsRepository repository,
}) async {
  final stack = await buildAuthStack();
  stack.authCubit.setAuthenticated(sampleUser());
  final router = AppRouter.create(
    authCubit: stack.authCubit,
    initialLocation: initialLocation,
  );

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportsRepository>.value(value: repository),
        RepositoryProvider<AuthRepository>.value(value: stack.repository),
        RepositoryProvider<NotificationsRepository>.value(
          value: FakeNotificationsRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: stack.authCubit),
          BlocProvider.value(value: stack.loginCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Login validation', (tester) async {
    final stack = await buildAuthStack();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(
            value: FakeReportsRepository(),
          ),
          RepositoryProvider<NotificationsRepository>.value(
            value: FakeNotificationsRepository(),
          ),
          BlocProvider.value(value: stack.authCubit),
          BlocProvider.value(value: stack.loginCubit),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Profile render', (tester) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());

    await tester.pumpWidget(
      BlocProvider.value(
        value: stack.authCubit,
        child: RepositoryProvider<AuthRepository>.value(
          value: stack.repository,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
    expect(find.text('minh.anh@civichub.vn'), findsWidgets);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('Profile logout requires confirmation', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());

    await tester.pumpWidget(
      BlocProvider.value(
        value: stack.authCubit,
        child: RepositoryProvider<AuthRepository>.value(
          value: stack.repository,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile_logout_button')),
    );
    await tester.tap(find.byKey(const ValueKey('profile_logout_button')));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(stack.authCubit.state.status, AuthStatus.authenticated);
  });

  testWidgets('Bottom navigation changes tab', (tester) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());

    final router = AppRouter.create(authCubit: stack.authCubit);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(
            value: FakeReportsRepository(),
          ),
          RepositoryProvider<AuthRepository>.value(value: stack.repository),
          RepositoryProvider<NotificationsRepository>.value(
            value: FakeNotificationsRepository(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: stack.authCubit),
            BlocProvider.value(value: stack.loginCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.assignment_outlined).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Filter workspace'), findsOneWidget);
  });

  testWidgets('Home renders authenticated greeting and report data', (
    tester,
  ) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(
          content: [
            sampleReport(id: 1, title: 'Street light outage'),
            sampleReport(id: 2, title: 'Drain blocked'),
          ],
          totalElements: 8,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: BlocProvider.value(
          value: stack.authCubit,
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );

    expect(find.text('Loading summary'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Hello, Nguyen'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Street light outage'), findsOneWidget);
    expect(repository.calls.single.size, 5);
  });

  testWidgets('Home shows empty state without fake report data', (
    tester,
  ) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());
    final repository = FakeReportsRepository(
      pages: [sampleReportsPage(content: const [], totalElements: 0)],
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: BlocProvider.value(
          value: stack.authCubit,
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No reports yet'), findsOneWidget);
    expect(find.text('Street light outage'), findsNothing);
    expect(find.text('Road repair'), findsNothing);
  });

  testWidgets('Home shows error and retry state', (tester) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());
    final repository = FakeReportsRepository()..error = ApiException.network;

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: BlocProvider.value(
          value: stack.authCubit,
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load summary'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(2));
    expect(find.text('Broken sidewalk'), findsOneWidget);
  });

  testWidgets('Home navigation opens create and reports routes', (
    tester,
  ) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());
    final repository = FakeReportsRepository();
    final router = AppRouter.create(
      authCubit: stack.authCubit,
      initialLocation: AppRoutes.home,
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: stack.authCubit),
            BlocProvider.value(value: stack.loginCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Report'));
    await tester.tap(find.text('Create Report'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateReportScreen), findsOneWidget);

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Reports').first);
    await tester.pumpAndSettle();
    expect(find.text('Reports'), findsWidgets);
  });

  testWidgets('Notifications screen does not show fake alerts', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<NotificationsRepository>.value(
        value: FakeNotificationsRepository(),
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Mock alerts'), findsNothing);
    expect(find.text('Report received'), findsNothing);
  });

  testWidgets('Reports screen loads reports', (tester) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(
            value: FakeReportsRepository(),
          ),
          RepositoryProvider<NotificationsRepository>.value(
            value: FakeNotificationsRepository(),
          ),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Broken sidewalk'), findsOneWidget);
    expect(find.text('Roads'), findsWidgets);
    expect(find.text('Newest'), findsWidgets);
    expect(find.text('All categories'), findsOneWidget);
  });

  testWidgets('Reports screen applies category and sort controls', (
    tester,
  ) async {
    final repository = FakeReportsRepository(
      pages: [
        sampleReportsPage(content: [sampleReport(id: 1)]),
        sampleReportsPage(content: const []),
        sampleReportsPage(content: const []),
      ],
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
          RepositoryProvider<NotificationsRepository>.value(
            value: FakeNotificationsRepository(),
          ),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Roads').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roads').first);
    await tester.pumpAndSettle();
    expect(repository.calls.last.categoryId, 7);

    await tester.ensureVisible(find.byTooltip('Sort reports').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sort reports').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title A-Z').last);
    await tester.pumpAndSettle();

    expect(repository.calls.last.sortBy, 'title');
    expect(repository.calls.last.direction, 'ASC');
  });

  testWidgets('Create report validates required fields', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(
            value: FakeReportsRepository(),
          ),
        ],
        child: const MaterialApp(home: CreateReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roads').last);
    await tester.pumpAndSettle();
    final submitButton = find.widgetWithText(FilledButton, 'Submit Report');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);
    expect(find.text('Address is required'), findsOneWidget);
  });

  testWidgets('Create report submits and pops on success', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeReportsRepository();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: MaterialApp(
          routes: {
            '/': (_) => const Scaffold(body: Text('Reports refreshed')),
            '/create': (_) => const CreateReportScreen(),
          },
          initialRoute: '/create',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ward 1');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roads').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).at(3));
    await tester.enterText(find.byType(TextFormField).at(3), 'Road hazard');
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'Large pothole near the bus stop',
    );
    final submitButton = find.widgetWithText(FilledButton, 'Submit Report');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.createRequests.single.title, 'Road hazard');
    expect(repository.createRequests.single.categoryId, 7);
    expect(repository.createRequests.single.imageUrls, isEmpty);
    expect(find.text('Reports refreshed'), findsOneWidget);
  });

  testWidgets('Create report shows reusable location picker', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(
            value: FakeReportsRepository(),
          ),
        ],
        child: const MaterialApp(home: CreateReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Use Current Location'));

    expect(find.text('Use Current Location'), findsOneWidget);
    expect(
      find.textContaining('Tap the map or drag the marker'),
      findsOneWidget,
    );
  });

  testWidgets('Report detail loads and shows empty images state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(id: 12);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: const MaterialApp(home: ReportDetailScreen(reportId: 12)),
      ),
    );

    expect(find.text('Loading report'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Broken sidewalk'), findsOneWidget);
    expect(find.text('Uneven pavement near the bus stop.'), findsOneWidget);
    expect(find.text('No images'), findsOneWidget);
    expect(find.byType(LocationPreviewCard), findsOneWidget);
  });

  testWidgets('Report detail renders image previews', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(id: 12).copyWithImages([
        const ReportImage(
          id: 1,
          url: 'https://example.com/report.jpg',
          displayOrder: 0,
        ),
      ]);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: const MaterialApp(home: ReportDetailScreen(reportId: 12)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Images'), findsOneWidget);
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('Report detail shows not found state', (tester) async {
    final repository = FakeReportsRepository()
      ..detailError = ApiException.notFound.copyWith(
        message: 'Report not found',
      );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: const MaterialApp(home: ReportDetailScreen(reportId: 404)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report not found'), findsWidgets);
  });

  testWidgets('Detail route with malformed ID does not request report 0', (
    tester,
  ) async {
    final repository = FakeReportsRepository();

    await pumpRouterApp(
      tester,
      initialLocation: '${AppRoutes.reportDetail}/abc',
      repository: repository,
    );

    expect(find.text('Invalid report link'), findsOneWidget);
    expect(find.text('Return to Reports'), findsOneWidget);
    expect(repository.detailCalls, isEmpty);
  });

  testWidgets('Detail route with zero ID shows safe invalid-route behavior', (
    tester,
  ) async {
    final repository = FakeReportsRepository();

    await pumpRouterApp(
      tester,
      initialLocation: '${AppRoutes.reportDetail}/0',
      repository: repository,
    );

    expect(find.text('Invalid report link'), findsOneWidget);
    expect(repository.detailCalls, isEmpty);
  });

  testWidgets(
    'Detail route with negative ID shows safe invalid-route behavior',
    (tester) async {
      final repository = FakeReportsRepository();

      await pumpRouterApp(
        tester,
        initialLocation: '${AppRoutes.reportDetail}/-3',
        repository: repository,
      );

      expect(find.text('Invalid report link'), findsOneWidget);
      expect(repository.detailCalls, isEmpty);
    },
  );

  testWidgets('Report detail disables edit and cancel for non-pending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(
        id: 12,
        status: ReportStatus.inProgress,
      );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: const MaterialApp(home: ReportDetailScreen(reportId: 12)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit report'), findsNothing);
    expect(find.byTooltip('Cancel report'), findsNothing);
    expect(
      find.text('Only pending reports can be edited or cancelled.'),
      findsOneWidget,
    );
  });

  testWidgets('Report detail confirms and cancels pending report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(id: 12);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: const MaterialApp(home: ReportDetailScreen(reportId: 12)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cancel report'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this report?'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls.single, 12);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Report cancelled.'), findsOneWidget);
  });

  testWidgets('Edit report submits updated values and pops', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeReportsRepository();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: MaterialApp(
          routes: {
            '/': (_) => const Scaffold(body: Text('Detail refreshed')),
            '/edit': (_) => EditReportScreen(
              reportId: 12,
              initialReport: sampleReportDetail(id: 12),
            ),
          },
          initialRoute: '/edit',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(TextFormField).at(3));
    await tester.enterText(find.byType(TextFormField).at(3), 'Updated title');
    final updateButton = find.widgetWithText(FilledButton, 'Update Report');
    await tester.ensureVisible(updateButton);
    await tester.pumpAndSettle();
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(repository.updateRequests.single.id, 12);
    expect(repository.updateRequests.single.request.title, 'Updated title');
    expect(find.text('Detail refreshed'), findsOneWidget);
  });

  testWidgets('Edit route uses matching extra without fetching detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeReportsRepository();
    final router = await pumpRouterApp(
      tester,
      initialLocation: AppRoutes.reports,
      repository: repository,
    );

    router.go(
      AppRoutes.editReportPath(12),
      extra: sampleReportDetail(id: 12, title: 'Extra title'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Report'), findsOneWidget);
    expect(find.text('Extra title'), findsOneWidget);
    expect(repository.detailCalls, isEmpty);
  });

  testWidgets('Edit route works when GoRouter.extra is absent', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(id: 12, title: 'Fetched title');

    await pumpRouterApp(
      tester,
      initialLocation: AppRoutes.editReportPath(12),
      repository: repository,
    );

    expect(find.text('Edit Report'), findsOneWidget);
    expect(find.text('Fetched title'), findsOneWidget);
    expect(repository.detailCalls, [12]);
  });

  testWidgets('Edit route ignores mismatched extra and fetches by path ID', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(id: 12, title: 'Trusted title');
    final router = await pumpRouterApp(
      tester,
      initialLocation: AppRoutes.reports,
      repository: repository,
    );

    router.go(
      AppRoutes.editReportPath(12),
      extra: sampleReportDetail(id: 99, title: 'Mismatched title'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trusted title'), findsOneWidget);
    expect(find.text('Mismatched title'), findsNothing);
    expect(repository.detailCalls, [12]);
  });

  testWidgets('Non-pending report loaded through edit route is non-editable', (
    tester,
  ) async {
    final repository = FakeReportsRepository()
      ..detailReport = sampleReportDetail(
        id: 12,
        status: ReportStatus.inProgress,
      );

    await pumpRouterApp(
      tester,
      initialLocation: AppRoutes.editReportPath(12),
      repository: repository,
    );

    expect(find.text('Report cannot be edited'), findsOneWidget);
    expect(find.text('Only pending reports can be updated.'), findsOneWidget);
    expect(find.text('Update Report'), findsNothing);
    expect(repository.detailCalls, [12]);
  });

  testWidgets('Reports list opens report detail', (tester) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());
    final repository = FakeReportsRepository();
    final router = AppRouter.create(
      authCubit: stack.authCubit,
      initialLocation: AppRoutes.reports,
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReportsRepository>.value(value: repository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: stack.authCubit),
            BlocProvider.value(value: stack.loginCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Broken sidewalk').first);
    await tester.pumpAndSettle();

    expect(find.text('Report Detail'), findsOneWidget);
    expect(repository.detailCalls.single, 1);
  });

  testWidgets('Login loading state', (tester) async {
    final completer = Completer<LoginResponse>();
    final stack = await buildAuthStack(loginFuture: completer.future);
    await stack.authCubit.bootstrap();
    final router = AppRouter.create(
      authCubit: stack.authCubit,
      initialLocation: AppRoutes.login,
    );

    await tester.pumpWidget(
      RepositoryProvider<ReportsRepository>.value(
        value: FakeReportsRepository(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: stack.authCubit),
            BlocProvider.value(value: stack.loginCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'citizen@civichub.vn',
    );
    await tester.enterText(find.byType(TextFormField).last, 'strongPassword');
    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Signing In...'), findsOneWidget);

    completer.complete(sampleLoginResponse());
    await tester.pumpAndSettle();

    expect(stack.loginCubit.state.status, LoginStatus.success);
  });

  testWidgets('Route guard unauthenticated', (tester) async {
    final stack = await buildAuthStack();
    await stack.authCubit.bootstrap();

    final router = AppRouter.create(
      authCubit: stack.authCubit,
      initialLocation: AppRoutes.profile,
    );

    await tester.pumpWidget(
      RepositoryProvider<ReportsRepository>.value(
        value: FakeReportsRepository(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: stack.authCubit),
            BlocProvider.value(value: stack.loginCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Citizen Login'), findsOneWidget);
  });

  testWidgets('Route guard authenticated', (tester) async {
    final stack = await buildAuthStack();
    stack.authCubit.setAuthenticated(sampleUser());
    final router = AppRouter.create(
      authCubit: stack.authCubit,
      initialLocation: AppRoutes.login,
    );

    await tester.pumpWidget(
      RepositoryProvider<ReportsRepository>.value(
        value: FakeReportsRepository(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: stack.authCubit),
            BlocProvider.value(value: stack.loginCubit),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Report'), findsOneWidget);
  });

  testWidgets('Splash retry triggers bootstrap again', (tester) async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final remote = FakeAuthRemoteDataSource(
      currentUserError: ApiException.network,
    );
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);

    await authCubit.bootstrap();

    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(remote.currentUserCalls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(remote.currentUserCalls, 2);
    expect(await storage.hasAccessToken(), isTrue);
  });
}
