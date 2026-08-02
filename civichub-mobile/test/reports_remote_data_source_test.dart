import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:civichub_mobile/core/network/api_client.dart';
import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:civichub_mobile/features/reports/domain/models/create_report_request.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_image_upload_file.dart';
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
  test('Remote data source loads public categories without auth', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final adapter = JsonAdapter(const {
      'success': true,
      'message': 'Active categories',
      'data': [
        {
          'id': 7,
          'name': 'Roads',
          'description': 'Road issues',
          'icon': 'road',
          'isActive': true,
        },
      ],
    });
    final client = ApiClient(tokenStorage: storage);
    client.dio.httpClientAdapter = adapter;
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    final categories = await dataSource.getCategories();

    expect(adapter.request?.path, '/api/categories');
    expect(adapter.request?.headers['Authorization'], isNull);
    expect(categories.single.name, 'Roads');
  });

  test(
    'Remote data source posts verified create report body with auth',
    () async {
      final storage = MemoryAuthTokenStorage();
      await storage.saveAccessToken('jwt-token');
      final adapter = JsonAdapter(const {
        'success': true,
        'message': 'Report created',
        'data': {
          'id': 12,
          'title': 'Road hazard',
          'description': 'Large pothole',
          'address': 'Ward 1',
          'status': 'PENDING',
          'latitude': 10.77,
          'longitude': 106.7,
          'categoryId': 7,
          'categoryName': 'Roads',
          'images': [
            {'id': 1, 'url': 'https://example.com/a.jpg', 'displayOrder': 0},
          ],
        },
      }, statusCode: 201);
      final client = ApiClient(tokenStorage: storage);
      client.dio.httpClientAdapter = adapter;
      final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

      final created = await dataSource.createReport(
        const CreateReportRequest(
          title: ' Road hazard ',
          description: ' Large pothole ',
          address: ' Ward 1 ',
          categoryId: 7,
          latitude: 10.77,
          longitude: 106.7,
          imageUrls: [' https://example.com/a.jpg '],
        ),
      );

      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.path, '/api/reports');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(adapter.request?.data, {
        'title': 'Road hazard',
        'description': 'Large pothole',
        'address': 'Ward 1',
        'latitude': 10.77,
        'longitude': 106.7,
        'categoryId': 7,
        'imageUrls': ['https://example.com/a.jpg'],
      });
      expect(created.status, ReportStatus.pending);
      expect(created.images.single.url, 'https://example.com/a.jpg');
    },
  );

  test(
    'Remote data source uploads report image as multipart with auth',
    () async {
      final storage = MemoryAuthTokenStorage();
      await storage.saveAccessToken('jwt-token');
      final adapter = JsonAdapter(const {
        'success': true,
        'message': 'Report image uploaded',
        'data': {
          'url': 'http://localhost:8080/uploads/report-images/a.png',
          'fileName': 'a.png',
          'contentType': 'image/png',
          'size': 4,
        },
      }, statusCode: 201);
      final client = ApiClient(tokenStorage: storage);
      client.dio.httpClientAdapter = adapter;
      final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

      final uploaded = await dataSource.uploadReportImage(
        ReportImageUploadFile(
          fileName: 'a.png',
          contentType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      );

      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.path, '/api/reports/images');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(adapter.request?.data, isA<FormData>());
      expect(uploaded.url, 'http://localhost:8080/uploads/report-images/a.png');
      expect(uploaded.contentType, 'image/png');
    },
  );

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
        search: 'road',
        status: ReportStatus.pending,
        categoryId: 7,
        sortBy: 'createdAt',
        direction: 'DESC',
      );

      expect(adapter.request?.path, '/api/reports/my');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(adapter.request?.queryParameters['search'], 'road');
      expect(adapter.request?.queryParameters['status'], 'PENDING');
      expect(adapter.request?.queryParameters['categoryId'], 7);
      expect(adapter.request?.queryParameters['sortBy'], 'createdAt');
      expect(adapter.request?.queryParameters['direction'], 'DESC');
      expect(page.content.single.id, 1);
    },
  );

  test(
    'Remote data source fetches verified report detail endpoint with auth',
    () async {
      final storage = MemoryAuthTokenStorage();
      await storage.saveAccessToken('jwt-token');
      final adapter = JsonAdapter(const {
        'success': true,
        'message': 'Report',
        'data': {
          'id': 12,
          'title': 'Road hazard',
          'description': 'Large pothole',
          'address': 'Ward 1',
          'status': 'IN_PROGRESS',
          'latitude': 10.77,
          'longitude': 106.7,
          'categoryId': 7,
          'categoryName': 'Roads',
          'departmentId': 3,
          'departmentName': 'Public Works',
          'citizenId': 1,
          'citizenName': 'Nguyen Minh Anh',
          'images': [
            {'id': 2, 'url': 'https://example.com/b.jpg', 'displayOrder': 0},
          ],
          'createdAt': '2026-07-20T10:15:00',
          'updatedAt': '2026-07-21T11:30:00',
        },
      });
      final client = ApiClient(tokenStorage: storage);
      client.dio.httpClientAdapter = adapter;
      final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

      final detail = await dataSource.getMyReport(12);

      expect(adapter.request?.method, 'GET');
      expect(adapter.request?.path, '/api/reports/my/12');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(detail.status, ReportStatus.inProgress);
      expect(detail.images.single.url, 'https://example.com/b.jpg');
    },
  );

  test(
    'Remote data source puts verified update report body with auth',
    () async {
      final storage = MemoryAuthTokenStorage();
      await storage.saveAccessToken('jwt-token');
      final adapter = JsonAdapter(const {
        'success': true,
        'message': 'Report updated',
        'data': {
          'id': 12,
          'title': 'Updated title',
          'description': 'Updated description',
          'address': 'Updated address',
          'status': 'PENDING',
          'categoryId': 7,
          'categoryName': 'Roads',
          'images': [],
        },
      });
      final client = ApiClient(tokenStorage: storage);
      client.dio.httpClientAdapter = adapter;
      final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

      final updated = await dataSource.updateMyReport(
        12,
        const CreateReportRequest(
          title: ' Updated title ',
          description: ' Updated description ',
          address: ' Updated address ',
          categoryId: 7,
          latitude: 10.77,
          longitude: 106.7,
          imageUrls: [' https://example.com/report.jpg '],
        ),
      );

      expect(adapter.request?.method, 'PUT');
      expect(adapter.request?.path, '/api/reports/my/12');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(adapter.request?.data, {
        'title': 'Updated title',
        'description': 'Updated description',
        'address': 'Updated address',
        'latitude': 10.77,
        'longitude': 106.7,
        'categoryId': 7,
        'imageUrls': ['https://example.com/report.jpg'],
      });
      expect(updated.title, 'Updated title');
    },
  );

  test(
    'Remote data source patches verified cancel endpoint with auth',
    () async {
      final storage = MemoryAuthTokenStorage();
      await storage.saveAccessToken('jwt-token');
      final adapter = JsonAdapter(const {
        'success': true,
        'message': 'Report cancelled',
        'data': {
          'id': 12,
          'title': 'Road hazard',
          'description': 'Large pothole',
          'address': 'Ward 1',
          'status': 'CANCELLED',
          'images': [],
        },
      });
      final client = ApiClient(tokenStorage: storage);
      client.dio.httpClientAdapter = adapter;
      final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

      final cancelled = await dataSource.cancelMyReport(12);

      expect(adapter.request?.method, 'PATCH');
      expect(adapter.request?.path, '/api/reports/my/12/cancel');
      expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
      expect(adapter.request?.data, isNull);
      expect(cancelled.status, ReportStatus.cancelled);
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

  test('Remote data source maps report not found', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'message': 'Report not found',
    }, statusCode: 404);
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.getMyReport(404),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.notFound,
        ),
      ),
    );
  });

  test('Remote data source rejects malformed detail image response', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'success': true,
      'message': 'Report',
      'data': {
        'id': 12,
        'title': 'Road hazard',
        'description': 'Large pothole',
        'address': 'Ward 1',
        'status': 'PENDING',
        'images': 'not-a-list',
      },
    });
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.getMyReport(12),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('Remote data source rejects malformed create wrapper', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'success': true,
      'message': 'Report created',
    });
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.createReport(
        const CreateReportRequest(
          title: 'Road hazard',
          description: 'Large pothole',
          address: 'Ward 1',
          categoryId: 7,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('Remote data source rejects malformed update wrapper', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'success': true,
      'message': 'Report updated',
    });
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.updateMyReport(
        12,
        const CreateReportRequest(
          title: 'Road hazard',
          description: 'Large pothole',
          address: 'Ward 1',
          categoryId: 7,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('Remote data source maps cancel conflict', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = JsonAdapter(const {
      'message': 'Only pending reports can be cancelled',
    }, statusCode: 409);
    final dataSource = ReportsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.cancelMyReport(12),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.conflict,
        ),
      ),
    );
  });
}
