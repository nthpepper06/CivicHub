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

void main() {
  testWidgets('Profile renders backend user fields', (tester) async {
    final stack = _profileStack();

    await tester.pumpWidget(_app(stack));
    await tester.pumpAndSettle();

    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
    expect(find.text('minh.anh@civichub.vn'), findsWidgets);
    expect(find.text('+84 912 345 678'), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('2026-07-01'), findsOneWidget);
  });

  testWidgets('Profile failure retries successfully', (tester) async {
    final remote = FakeAuthRemoteDataSource(
      currentUserError: ApiException.network,
    );
    final stack = _profileStack(remote: remote);

    await tester.pumpWidget(_app(stack));
    await tester.pumpAndSettle();
    expect(find.text('Profile refresh failed'), findsOneWidget);

    remote.currentUserError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
  });

  testWidgets('Edit profile validates required fields', (tester) async {
    final stack = _profileStack(initialLocation: AppRoutes.editProfile);

    await tester.pumpWidget(_app(stack));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('Edit profile updates session and returns to profile', (
    tester,
  ) async {
    final stack = _profileStack();

    await tester.pumpWidget(_app(stack));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tran Lan Anh');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(stack.remote.updateUserCalls, 1);
    expect(stack.authCubit.state.user?.fullName, 'Tran Lan Anh');
    expect(find.text('Tran Lan Anh'), findsOneWidget);
  });
}

({
  FakeAuthRemoteDataSource remote,
  AuthRepository repository,
  AuthCubit authCubit,
  LoginCubit loginCubit,
  String initialLocation,
})
_profileStack({FakeAuthRemoteDataSource? remote, String? initialLocation}) {
  final storage = MemoryAuthTokenStorage();
  final dataSource = remote ?? FakeAuthRemoteDataSource();
  final repository = AuthRepositoryImpl(
    remoteDataSource: dataSource,
    tokenStorage: storage,
  );
  final authCubit = AuthCubit(authRepository: repository)
    ..setAuthenticated(sampleUser());
  final loginCubit = LoginCubit(
    authRepository: repository,
    authCubit: authCubit,
  );
  return (
    remote: dataSource,
    repository: repository,
    authCubit: authCubit,
    loginCubit: loginCubit,
    initialLocation: initialLocation ?? AppRoutes.profile,
  );
}

Widget _app(
  ({
    FakeAuthRemoteDataSource remote,
    AuthRepository repository,
    AuthCubit authCubit,
    LoginCubit loginCubit,
    String initialLocation,
  })
  stack,
) {
  final router = AppRouter.create(
    authCubit: stack.authCubit,
    initialLocation: stack.initialLocation,
  );
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: stack.repository),
      RepositoryProvider<ReportsRepository>.value(
        value: FakeReportsRepository(),
      ),
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
  );
}
