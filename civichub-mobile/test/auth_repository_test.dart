import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/auth/data/models/login_request.dart';
import 'package:civichub_mobile/features/auth/data/models/login_response.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/domain/models/auth_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Login stores token', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );

    final session = await repository.login(
      const LoginRequest(email: 'citizen@civichub.vn', password: 'secret'),
    );

    expect(session.accessToken, 'jwt-token');
    expect(await storage.readAccessToken(), 'jwt-token');
  });

  test('Bootstrap without token returns null', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );

    expect(await repository.bootstrapSession(), isNull);
  });

  test('Bootstrap invalid token clears storage', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('stale-token');

    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserError: ApiException.unauthorized,
      ),
      tokenStorage: storage,
    );

    expect(await repository.bootstrapSession(), isNull);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('Bootstrap network failure keeps token and rethrows', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');

    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserError: ApiException.network,
      ),
      tokenStorage: storage,
    );

    await expectLater(
      repository.bootstrapSession(),
      throwsA(isA<ApiException>()),
    );
    expect(await storage.hasAccessToken(), isTrue);
  });

  test('Login with empty token does not save token', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        loginResponse: LoginResponse(
          accessToken: ' ',
          tokenType: 'Bearer',
          expiresIn: 86400,
          user: sampleUser(),
        ),
      ),
      tokenStorage: storage,
    );

    await expectLater(
      repository.login(
        const LoginRequest(email: 'citizen@civichub.vn', password: 'secret'),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('STAFF login is accepted and stores token', () async {
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

    final session = await repository.login(
      const LoginRequest(email: 'staff@civichub.vn', password: 'secret'),
    );

    expect(session.user.role, UserRole.staff);
    expect(await storage.readAccessToken(), 'jwt-token');
  });

  test('ADMIN login is rejected', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('old-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        loginResponse: LoginResponse(
          accessToken: 'jwt-token',
          tokenType: 'Bearer',
          expiresIn: 86400,
          user: sampleUser(role: UserRole.admin),
        ),
      ),
      tokenStorage: storage,
    );

    await expectLater(
      repository.login(
        const LoginRequest(email: 'admin@civichub.vn', password: 'secret'),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.forbidden,
        ),
      ),
    );
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('STAFF bootstrap restores session', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserResponse: sampleUser(role: UserRole.staff),
      ),
      tokenStorage: storage,
    );

    final user = await repository.bootstrapSession();

    expect(user?.role, UserRole.staff);
    expect(await storage.hasAccessToken(), isTrue);
  });

  test('ADMIN bootstrap is rejected and clears token', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(
        currentUserResponse: sampleUser(role: UserRole.admin),
      ),
      tokenStorage: storage,
    );

    expect(await repository.bootstrapSession(), isNull);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('Logout clears token', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');

    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );

    await repository.logout();

    expect(await storage.hasAccessToken(), isFalse);
  });

  test('Logout is idempotent', () async {
    final storage = MemoryAuthTokenStorage();
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );

    await repository.logout();
    await repository.logout();

    expect(await storage.hasAccessToken(), isFalse);
  });
}
