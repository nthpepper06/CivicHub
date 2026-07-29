import 'dart:async';
import 'dart:typed_data';

import 'package:civichub_mobile/core/network/api_client.dart';
import 'package:civichub_mobile/core/network/unauthorized_handler.dart';
import 'package:civichub_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:civichub_mobile/features/auth/presentation/cubit/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

class CountingUnauthorizedHandler implements UnauthorizedHandler {
  CountingUnauthorizedHandler({this.onHandle});

  final Future<void> Function()? onHandle;
  int calls = 0;

  @override
  Future<void> handleUnauthorized() async {
    calls += 1;
    await onHandle?.call();
  }
}

class CapturedRequest {
  CapturedRequest(this.path, this.headers, this.extra);

  final String path;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> extra;
}

class QueueAdapter implements HttpClientAdapter {
  QueueAdapter(this.statusCodes);

  final List<int> statusCodes;
  final requests = <CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      CapturedRequest(
        options.path,
        Map<String, dynamic>.from(options.headers),
        Map<String, dynamic>.from(options.extra),
      ),
    );
    final statusCode = statusCodes.removeAt(0);
    return ResponseBody.fromString(
      '{"success":false,"message":"Unauthorized"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Login request does not attach Authorization header', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final adapter = QueueAdapter([200]);
    final client = ApiClient(tokenStorage: storage);
    client.dio.httpClientAdapter = adapter;

    await client.dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: const {'email': 'citizen@civichub.vn', 'password': 'secret'},
      options: Options(extra: {ApiClient.requiresAuthExtraKey: false}),
    );

    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('Protected request attaches Bearer token', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final adapter = QueueAdapter([200]);
    final client = ApiClient(tokenStorage: storage);
    client.dio.httpClientAdapter = adapter;

    await client.dio.get<Map<String, dynamic>>('/api/auth/me');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer jwt-token',
    );
  });

  test('Protected 401 calls unauthorized handler and clears token', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final handler = CountingUnauthorizedHandler(
      onHandle: storage.deleteAccessToken,
    );
    final adapter = QueueAdapter([401]);
    final client = ApiClient(
      tokenStorage: storage,
      unauthorizedHandler: handler,
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/api/auth/me'),
      throwsA(isA<DioException>()),
    );

    expect(handler.calls, 1);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('Protected 401 moves AuthCubit to unauthenticated', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final repository = AuthRepositoryImpl(
      remoteDataSource: FakeAuthRemoteDataSource(),
      tokenStorage: storage,
    );
    final authCubit = AuthCubit(authRepository: repository);
    authCubit.setAuthenticated(sampleUser());
    final adapter = QueueAdapter([401]);
    final client = ApiClient(
      tokenStorage: storage,
      unauthorizedHandler: authCubit,
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/api/reports'),
      throwsA(isA<DioException>()),
    );

    expect(authCubit.state.status, AuthStatus.unauthenticated);
    expect(authCubit.state.user, isNull);
  });

  test('Login 401 does not call global unauthorized handler', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final handler = CountingUnauthorizedHandler(
      onHandle: storage.deleteAccessToken,
    );
    final adapter = QueueAdapter([401]);
    final client = ApiClient(
      tokenStorage: storage,
      unauthorizedHandler: handler,
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        options: Options(extra: {ApiClient.requiresAuthExtraKey: false}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(handler.calls, 0);
    expect(await storage.hasAccessToken(), isTrue);
  });

  test('Concurrent protected 401 responses handle unauthorized once', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final completer = Completer<void>();
    final handler = CountingUnauthorizedHandler(
      onHandle: () => completer.future,
    );
    final adapter = QueueAdapter([401, 401]);
    final client = ApiClient(
      tokenStorage: storage,
      unauthorizedHandler: handler,
    );
    client.dio.httpClientAdapter = adapter;

    final first = client.dio.get<Map<String, dynamic>>('/api/auth/me');
    final second = client.dio.get<Map<String, dynamic>>('/api/auth/me');
    await Future<void>.delayed(Duration.zero);
    completer.complete();

    await expectLater(first, throwsA(isA<DioException>()));
    await expectLater(second, throwsA(isA<DioException>()));

    expect(handler.calls, 1);
  });
}
