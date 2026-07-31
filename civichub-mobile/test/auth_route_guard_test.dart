import 'package:civichub_mobile/app/routing/app_router.dart';
import 'package:civichub_mobile/app/routing/app_routes.dart';
import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Widget _buildRouterApp({
  required AuthCubit authCubit,
  required LoginCubit loginCubit,
  required AuthRepository authRepository,
  required String initialLocation,
}) {
  final router = AppRouter.create(
    authCubit: authCubit,
    initialLocation: initialLocation,
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authCubit),
      BlocProvider.value(value: loginCubit),
    ],
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportsRepository>.value(
          value: FakeReportsRepository(),
        ),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<NotificationsRepository>.value(
          value: FakeNotificationsRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('Route guard unauthenticated', (tester) async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final loginCubit = LoginCubit(
      authRepository: repository,
      authCubit: authCubit,
    );
    await authCubit.bootstrap();

    await tester.pumpWidget(
      _buildRouterApp(
        authCubit: authCubit,
        loginCubit: loginCubit,
        authRepository: repository,
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Citizen Login'), findsOneWidget);
  });

  testWidgets('Route guard authenticated', (tester) async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final loginCubit = LoginCubit(
      authRepository: repository,
      authCubit: authCubit,
    );
    authCubit.setAuthenticated(sampleUser());

    await tester.pumpWidget(
      _buildRouterApp(
        authCubit: authCubit,
        loginCubit: loginCubit,
        authRepository: repository,
        initialLocation: AppRoutes.login,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Report'), findsOneWidget);
  });

  testWidgets('Bootstrap failure stays on Splash error state', (tester) async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserError: ApiException.timeout,
      ),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final loginCubit = LoginCubit(
      authRepository: repository,
      authCubit: authCubit,
    );
    await authCubit.bootstrap();

    await tester.pumpWidget(
      _buildRouterApp(
        authCubit: authCubit,
        loginCubit: loginCubit,
        authRepository: repository,
        initialLocation: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Citizen Login'), findsNothing);
  });
}
