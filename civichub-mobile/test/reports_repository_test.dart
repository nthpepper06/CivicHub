import 'package:civichub_mobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:civichub_mobile/features/reports/data/models/report_summary_response.dart';
import 'package:civichub_mobile/features/reports/data/models/reports_page_response.dart';
import 'package:civichub_mobile/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:civichub_mobile/features/reports/domain/models/report_status.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReportsRemoteDataSource implements ReportsRemoteDataSource {
  FakeReportsRemoteDataSource(this.response);

  final ReportsPageResponse<ReportSummaryResponse> response;
  final calls = <Map<String, Object?>>[];

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
}
