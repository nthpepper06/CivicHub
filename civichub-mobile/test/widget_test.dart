import 'dart:async';

import 'package:civichub_mobile/app/routing/app_router.dart';
import 'package:civichub_mobile/app/routing/app_routes.dart';
import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/core/storage/auth_token_storage.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/domain/models/citizen_profile.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_state.dart';
import 'package:civichub_mobile/features/auth/presentation/screens/login_screen.dart';
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

Future<({AuthCubit authCubit, LoginCubit loginCubit, AuthTokenStorage storage})>
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
  return (authCubit: authCubit, loginCubit: loginCubit, storage: storage);
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
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
    expect(find.text('minh.anh@civichub.vn'), findsNWidgets(2));
    expect(find.text('Logout'), findsOneWidget);
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

    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Reports'), findsOneWidget);
    expect(find.text('Reports'), findsWidgets);
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
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Broken sidewalk'), findsOneWidget);
    expect(find.text('Roads'), findsOneWidget);
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
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.tap(find.text('Submit Report'));
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Road hazard');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Large pothole near the bus stop',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roads').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'Ward 1');
    await tester.ensureVisible(find.byType(TextFormField).at(5));
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'https://example.com/report.jpg',
    );
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();

    expect(repository.createRequests.single.title, 'Road hazard');
    expect(repository.createRequests.single.categoryId, 7);
    expect(repository.createRequests.single.imageUrls, [
      'https://example.com/report.jpg',
    ]);
    expect(find.text('Reports refreshed'), findsOneWidget);
  });

  testWidgets('Create report GPS button shows limitation', (tester) async {
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

    await tester.ensureVisible(find.text('Use Current GPS'));
    await tester.tap(find.text('Use Current GPS'));
    await tester.pump();

    expect(find.textContaining('GPS is not available'), findsOneWidget);
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
    expect(find.byType(Image), findsOneWidget);
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
            '/edit': (_) =>
                EditReportScreen(report: sampleReportDetail(id: 12)),
          },
          initialRoute: '/edit',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated title');
    await tester.ensureVisible(find.text('Update Report'));
    await tester.tap(find.text('Update Report'));
    await tester.pumpAndSettle();

    expect(repository.updateRequests.single.id, 12);
    expect(repository.updateRequests.single.request.title, 'Updated title');
    expect(find.text('Detail refreshed'), findsOneWidget);
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
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: stack.authCubit),
          BlocProvider.value(value: stack.loginCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
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
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: stack.authCubit),
          BlocProvider.value(value: stack.loginCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
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
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: stack.authCubit),
          BlocProvider.value(value: stack.loginCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
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
