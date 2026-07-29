import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/auth/data/models/login_request.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_enums.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/login_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Login loading state and success', () async {
    final completer = Completer<LoginResponse>();
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(loginFuture: completer.future),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = LoginCubit(authRepository: repository, authCubit: authCubit);

    final future = cubit.submit(
      const LoginRequest(email: 'citizen@civichub.vn', password: 'secret'),
    );

    expect(cubit.state.status, LoginStatus.submitting);

    completer.complete(sampleLoginResponse());
    await future;

    expect(cubit.state.status, LoginStatus.success);
    expect(authCubit.state.status, AuthStatus.authenticated);
  });

  test('Login failure', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        loginError: ApiException.unauthorized,
      ),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = LoginCubit(authRepository: repository, authCubit: authCubit);

    await cubit.submit(
      const LoginRequest(email: 'citizen@civichub.vn', password: 'wrong'),
    );

    expect(cubit.state.status, LoginStatus.failure);
    expect(cubit.state.errorMessage, 'Invalid email or password.');
    expect(authCubit.state.status, AuthStatus.unknown);
  });

  test('Login rejects non-citizen account', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        loginResponse: LoginResponse(
          accessToken: 'jwt-token',
          tokenType: 'Bearer',
          expiresIn: 86400,
          user: sampleUser(role: UserRole.staff),
        ),
      ),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = LoginCubit(authRepository: repository, authCubit: authCubit);

    await cubit.submit(
      const LoginRequest(email: 'staff@civichub.vn', password: 'secret'),
    );

    expect(cubit.state.status, LoginStatus.failure);
    expect(
      cubit.state.errorMessage,
      'This app is available to citizen accounts only.',
    );
    expect(authCubit.state.status, AuthStatus.unknown);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('Invalid login response does not authenticate or save token', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        loginResponse: LoginResponse(
          accessToken: '',
          tokenType: 'Bearer',
          expiresIn: 86400,
          user: sampleUser(),
        ),
      ),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    final cubit = LoginCubit(authRepository: repository, authCubit: authCubit);

    await cubit.submit(
      const LoginRequest(email: 'citizen@civichub.vn', password: 'secret'),
    );

    expect(cubit.state.status, LoginStatus.failure);
    expect(authCubit.state.status, AuthStatus.unknown);
    expect(await storage.hasAccessToken(), isFalse);
  });
}
