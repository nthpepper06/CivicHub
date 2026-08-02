import 'dart:typed_data';

import 'package:civichub_mobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:civichub_mobile/features/reports/data/models/category_response.dart';
import 'package:civichub_mobile/features/reports/data/models/report_detail_response.dart';
import 'package:civichub_mobile/features/reports/data/models/report_image_upload_response.dart';
import 'package:civichub_mobile/features/reports/data/models/report_summary_response.dart';
import 'package:civichub_mobile/features/reports/data/models/reports_page_response.dart';
import 'package:civichub_mobile/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:civichub_mobile/features/reports/domain/models/create_report_request.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_image_upload_file.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReportsRemoteDataSource implements ReportsRemoteDataSource {
  FakeReportsRemoteDataSource(this.response);

  final ReportsPageResponse<ReportSummaryResponse> response;
  final calls = <Map<String, Object?>>[];
  final createRequests = <CreateReportRequest>[];

  @override
  Future<List<CategoryResponse>> getCategories() async {
    return [
      CategoryResponse.fromJson(const {
        'id': 7,
        'name': 'Roads',
        'description': 'Road issues',
        'icon': 'road',
        'isActive': true,
      }),
    ];
  }

  @override
  Future<ReportDetailResponse> createReport(CreateReportRequest request) async {
    createRequests.add(request);
    return ReportDetailResponse.fromJson(const {
      'id': 99,
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
    });
  }

  @override
  Future<ReportImageUploadResponse> uploadReportImage(
    ReportImageUploadFile file,
  ) async {
    return ReportImageUploadResponse(
      url: 'https://uploads.test/${file.fileName}',
      fileName: file.fileName,
      contentType: file.contentType,
      size: file.size,
    );
  }

  @override
  Future<ReportDetailResponse> getMyReport(int id) async {
    return ReportDetailResponse.fromJson({
      'id': id,
      'title': 'Road hazard',
      'description': 'Large pothole',
      'address': 'Ward 1',
      'status': 'PENDING',
      'images': const [],
    });
  }

  @override
  Future<ReportDetailResponse> updateMyReport(
    int id,
    CreateReportRequest request,
  ) async {
    createRequests.add(request);
    return ReportDetailResponse.fromJson({
      'id': id,
      'title': request.title,
      'description': request.description,
      'address': request.address,
      'status': 'PENDING',
      'images': const [],
    });
  }

  @override
  Future<ReportDetailResponse> cancelMyReport(int id) async {
    return ReportDetailResponse.fromJson({
      'id': id,
      'title': 'Road hazard',
      'description': 'Large pothole',
      'address': 'Ward 1',
      'status': 'CANCELLED',
      'images': const [],
    });
  }

  @override
  Future<ReportsPageResponse<ReportSummaryResponse>> getMyReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    String? sortBy,
    String? direction,
  }) async {
    calls.add({
      'page': page,
      'size': size,
      'search': search,
      'status': status,
      'categoryId': categoryId,
      'sortBy': sortBy,
      'direction': direction,
    });
    return response;
  }
}

void main() {
  test('Repository maps remote reports page to domain models', () async {
    final remote = FakeReportsRemoteDataSource(
      ReportsPageResponse(
        content: [
          ReportSummaryResponse.fromJson(const {
            'id': 42,
            'title': 'Street light outage',
            'address': 'Main square',
            'status': 'IN_PROGRESS',
            'categoryId': 3,
            'categoryName': 'Lighting',
            'departmentId': 9,
            'departmentName': 'Public Works',
            'citizenId': 1,
            'citizenName': 'Nguyen Minh Anh',
            'primaryImageUrl': 'https://example.com/light.jpg',
            'createdAt': '2026-07-20T10:15:00',
            'updatedAt': '2026-07-21T11:30:00',
          }),
        ],
        page: 0,
        size: 10,
        totalElements: 1,
        totalPages: 1,
        first: true,
        last: true,
      ),
    );
    final repository = ReportsRepositoryImpl(remoteDataSource: remote);

    final page = await repository.getMyReports(
      page: 0,
      size: 10,
      search: 'light',
      status: ReportStatus.inProgress,
      sortBy: 'createdAt',
      direction: 'DESC',
    );

    expect(page.content.single.id, 42);
    expect(page.content.single.status, ReportStatus.inProgress);
    expect(
      page.content.single.primaryImageUrl,
      'https://example.com/light.jpg',
    );
    expect(remote.calls.single['status'], ReportStatus.inProgress);
  });

  test('Report parser handles nullable and unknown fields safely', () {
    final report = ReportSummaryResponse.fromJson(const {
      'id': 7,
      'status': 'ESCALATED',
      'unexpected': 'ignored',
    }).toDomain();

    expect(report.id, 7);
    expect(report.title, '');
    expect(report.address, '');
    expect(report.status, ReportStatus.unknown);
    expect(report.categoryName, isNull);
    expect(report.createdAt, isNull);
  });

  test(
    'Repository maps categories and created report to domain models',
    () async {
      final remote = FakeReportsRemoteDataSource(
        const ReportsPageResponse(
          content: [],
          page: 0,
          size: 10,
          totalElements: 0,
          totalPages: 0,
          first: true,
          last: true,
        ),
      );
      final repository = ReportsRepositoryImpl(remoteDataSource: remote);

      final categories = await repository.getCategories();
      final created = await repository.createReport(
        const CreateReportRequest(
          title: 'Road hazard',
          description: 'Large pothole',
          address: 'Ward 1',
          categoryId: 7,
          latitude: 10.77,
          longitude: 106.7,
          imageUrls: ['https://example.com/a.jpg'],
        ),
      );

      expect(categories.single.name, 'Roads');
      expect(created.id, 99);
      expect(created.status, ReportStatus.pending);
      expect(created.images.single.url, 'https://example.com/a.jpg');
      expect(remote.createRequests.single.categoryId, 7);
    },
  );

  test('Repository uploads report image through remote data source', () async {
    final remote = FakeReportsRemoteDataSource(
      const ReportsPageResponse(
        content: [],
        page: 0,
        size: 10,
        totalElements: 0,
        totalPages: 0,
        first: true,
        last: true,
      ),
    );
    final repository = ReportsRepositoryImpl(remoteDataSource: remote);

    final uploaded = await repository.uploadReportImage(
      ReportImageUploadFile(
        fileName: 'field.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect(uploaded.url, 'https://uploads.test/field.png');
    expect(uploaded.contentType, 'image/png');
  });

  test('Repository maps detail fetch to domain model', () async {
    final remote = FakeReportsRemoteDataSource(
      const ReportsPageResponse(
        content: [],
        page: 0,
        size: 10,
        totalElements: 0,
        totalPages: 0,
        first: true,
        last: true,
      ),
    );
    final repository = ReportsRepositoryImpl(remoteDataSource: remote);

    final detail = await repository.getMyReport(44);

    expect(detail.id, 44);
    expect(detail.title, 'Road hazard');
    expect(detail.images, isEmpty);
  });

  test('Repository maps update and cancel to domain models', () async {
    final remote = FakeReportsRemoteDataSource(
      const ReportsPageResponse(
        content: [],
        page: 0,
        size: 10,
        totalElements: 0,
        totalPages: 0,
        first: true,
        last: true,
      ),
    );
    final repository = ReportsRepositoryImpl(remoteDataSource: remote);

    final updated = await repository.updateMyReport(
      44,
      const CreateReportRequest(
        title: 'Updated title',
        description: 'Updated description',
        address: 'Updated address',
        categoryId: 7,
      ),
    );
    final cancelled = await repository.cancelMyReport(44);

    expect(updated.title, 'Updated title');
    expect(cancelled.status, ReportStatus.cancelled);
  });
}
