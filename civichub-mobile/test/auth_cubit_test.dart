import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Auth bootstrap without token', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );
    final cubit = AuthCubit(authRepository: repository);

    await cubit.bootstrap();

    expect(cubit.state.status, AuthStatus.unauthenticated);
  });

  test('Auth bootstrap token valid', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );
    final cubit = AuthCubit(authRepository: repository);

    await cubit.bootstrap();

    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.user?.email, 'minh.anh@civichub.vn');
  });

  test('Auth bootstrap token invalid', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserError: ApiException.unauthorized,
      ),
      tokenStorage: storage,
    );
    final cubit = AuthCubit(authRepository: repository);

    await cubit.bootstrap();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('Auth bootstrap timeout fails without deleting token', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserError: ApiException.timeout,
      ),
      tokenStorage: storage,
    );
    final cubit = AuthCubit(authRepository: repository);

    await cubit.bootstrap();

    expect(cubit.state.status, AuthStatus.failure);
    expect(await storage.hasAccessToken(), isTrue);
  });

  test('Auth bootstrap network failure fails without deleting token', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserError: ApiException.network,
      ),
      tokenStorage: storage,
    );
    final cubit = AuthCubit(authRepository: repository);

    await cubit.bootstrap();

    expect(cubit.state.status, AuthStatus.failure);
    expect(await storage.hasAccessToken(), isTrue);
  });

  test('Logout clears session', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );
    final cubit = AuthCubit(authRepository: repository);

    cubit.setAuthenticated(sampleUser());
    await storage.saveAccessToken('jwt-token');
    await cubit.logout();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.user, isNull);
    expect(await storage.hasAccessToken(), isFalse);
  });
}
