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
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:civichub_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:civichub_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

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
