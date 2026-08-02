import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../reports/data/models/report_detail_response.dart';
import '../../../reports/data/models/report_summary_response.dart';
import '../../../reports/data/models/reports_page_response.dart';
import '../../../reports/domain/models/report_status.dart';
import '../models/staff_dashboard_summary_response.dart';

abstract class StaffRemoteDataSource {
  Future<StaffDashboardSummaryResponse> getDashboardSummary();

  Future<ReportsPageResponse<ReportSummaryResponse>> getRecentReports({
    required int size,
  });

  Future<ReportsPageResponse<ReportSummaryResponse>> getAssignedReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    int? citizenId,
    DateTime? createdFrom,
    DateTime? createdTo,
  });

  Future<ReportDetailResponse> getAssignedReport(int id);

  Future<ReportDetailResponse> updateAssignedReportStatus(
    int id,
    ReportStatus status, {
    String? resolutionSummary,
    String? workPerformed,
    String? publicNote,
    List<String> resolutionImageUrls,
  });
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<StaffDashboardSummaryResponse> getDashboardSummary() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.staffDashboardSummary,
      );
      return StaffDashboardSummaryResponse.fromJson(
        _responseData(response.data),
      );
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportsPageResponse<ReportSummaryResponse>> getRecentReports({
    required int size,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.staffDashboardRecent,
        queryParameters: _cleanParams({'size': size}),
      );
      return ReportsPageResponse.fromJson(
        _responseData(response.data),
        ReportSummaryResponse.fromJson,
      );
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportsPageResponse<ReportSummaryResponse>> getAssignedReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    int? citizenId,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.staffReports,
        queryParameters: _cleanParams({
          'page': page,
          'size': size,
          'search': search,
          'status': status == null || status == ReportStatus.unknown
              ? null
              : status.apiValue,
          'categoryId': categoryId,
          'citizenId': citizenId,
          'createdFrom': createdFrom?.toIso8601String(),
          'createdTo': createdTo?.toIso8601String(),
        }),
      );
      return ReportsPageResponse.fromJson(
        _responseData(response.data),
        ReportSummaryResponse.fromJson,
      );
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> getAssignedReport(int id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.staffReportDetail(id),
      );
      return ReportDetailResponse.fromJson(_responseData(response.data));
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> updateAssignedReportStatus(
    int id,
    ReportStatus status, {
    String? resolutionSummary,
    String? workPerformed,
    String? publicNote,
    List<String> resolutionImageUrls = const [],
  }) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.staffReportStatus(id),
        data: _cleanParams({
          'status': status.apiValue,
          'resolutionSummary': resolutionSummary,
          'workPerformed': workPerformed,
          'publicNote': publicNote,
          'resolutionImageUrls': resolutionImageUrls.isEmpty
              ? null
              : resolutionImageUrls,
        }),
      );
      return ReportDetailResponse.fromJson(_responseData(response.data));
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  Map<String, dynamic> _responseData(Map<String, dynamic>? responseBody) {
    final data = responseBody?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException.invalidResponse;
  }

  Map<String, dynamic> _cleanParams(Map<String, Object?> params) {
    return Map<String, dynamic>.fromEntries(
      params.entries.where((entry) {
        final value = entry.value;
        return value != null && (value is! String || value.trim().isNotEmpty);
      }),
    );
  }
}
