import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:civichub_mobile/core/network/api_client.dart';
import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

class JsonAdapter implements HttpClientAdapter {
  JsonAdapter(this.body, {this.statusCode = 200});

  final Map<String, dynamic> body;
  final int statusCode;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
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
  test(
    'Remote data source requests verified my reports endpoint with auth',
    () async {
      final storage = MemoryAuthTokenStorage();
      await storage.saveAccessToken('jwt-token');
      final adapter = JsonAdapter(const {
        'success': true,
        'message': 'My reports',
        'data': {
          'content': [
            {
              'id': 1,
              'title': 'Road hazard',
              'address': 'Ward 1',
              'status': 'PENDING',
            },
          ],
          'page': 0,
          'size': 10,
          'totalElements': 1,
          'totalPages': 1,
          'first': true,
          'last': true,
        },
      });
      final client = ApiClient(tokenStorage: storage);
      client.dio.httpClientAdapter = adapter;
      final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

      final page = await dataSource.getMyReports(
        page: 0,
        size: 10,
        status: ReportStatus.pending,
        sortBy: 'createdAt',
        direction: 'DESC',
      );

      expect(adapter.request?.path, '/api/reports/my');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(adapter.request?.queryParameters['status'], 'PENDING');
      expect(page.content.single.id, 1);
    },
  );

  test('Remote data source rejects malformed wrapped response', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'success': true,
      'message': 'My reports',
      'data': {'content': []},
    });
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.getMyReports(page: 0, size: 10),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('Remote data source maps unauthorized through ApiClient', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'success': false,
      'message': 'Unauthorized',
    }, statusCode: 401);
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.getMyReports(page: 0, size: 10),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.unauthorized,
        ),
      ),
    );
  });
}
