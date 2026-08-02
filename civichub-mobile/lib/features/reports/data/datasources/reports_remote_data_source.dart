import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_image_upload_file.dart';
import '../../domain/models/report_status.dart';
import '../models/category_response.dart';
import '../models/create_report_request_dto.dart';
import '../models/report_image_upload_response.dart';
import '../models/report_detail_response.dart';
import '../models/report_summary_response.dart';
import '../models/reports_page_response.dart';

abstract class ReportsRemoteDataSource {
  Future<List<CategoryResponse>> getCategories();

  Future<ReportDetailResponse> createReport(CreateReportRequest request);

  Future<ReportImageUploadResponse> uploadReportImage(
    ReportImageUploadFile file,
  );

  Future<ReportDetailResponse> getMyReport(int id);

  Future<ReportDetailResponse> updateMyReport(
    int id,
    CreateReportRequest request,
  );

  Future<ReportDetailResponse> cancelMyReport(int id);

  Future<ReportDetailResponse> confirmResolution(int id);

  Future<ReportDetailResponse> rateResolution(
    int id, {
    required int rating,
    String? comment,
  });

  Future<ReportsPageResponse<ReportSummaryResponse>> getMyReports({
    required int page,
    required int size,
    String? search,
    ReportStatus? status,
    int? categoryId,
    String? sortBy,
    String? direction,
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<CategoryResponse>> getCategories() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.categories,
        options: Options(extra: {ApiClient.requiresAuthExtraKey: false}),
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw ApiException.invalidResponse;
      }
      return data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid category item');
        }
        return CategoryResponse.fromJson(item);
      }).toList();
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> createReport(CreateReportRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.reports,
        data: CreateReportRequestDto(request).toJson(),
      );
      final data = _responseData(response.data);
      return ReportDetailResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportImageUploadResponse> uploadReportImage(
    ReportImageUploadFile file,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: file.fileName,
          contentType: DioMediaType.parse(file.contentType),
        ),
      });
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.reportImages,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      final data = _responseData(response.data);
      return ReportImageUploadResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> getMyReport(int id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.myReportDetail(id),
      );
      final data = _responseData(response.data);
      return ReportDetailResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> updateMyReport(
    int id,
    CreateReportRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        ApiEndpoints.myReportDetail(id),
        data: CreateReportRequestDto(request).toJson(),
      );
      final data = _responseData(response.data);
      return ReportDetailResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> cancelMyReport(int id) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.myReportCancel(id),
      );
      final data = _responseData(response.data);
      return ReportDetailResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> confirmResolution(int id) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.myReportConfirmResolution(id),
      );
      final data = _responseData(response.data);
      return ReportDetailResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<ReportDetailResponse> rateResolution(
    int id, {
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.myReportRating(id),
        data: {'rating': rating, 'comment': comment},
      );
      final data = _responseData(response.data);
      return ReportDetailResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
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
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.myReports,
        queryParameters: _cleanParams({
          'page': page,
          'size': size,
          'search': search,
          'status': status == null || status == ReportStatus.unknown
              ? null
              : status.apiValue,
          'categoryId': categoryId,
          'sortBy': sortBy,
          'direction': direction,
        }),
      );
      final data = _responseData(response.data);
      return ReportsPageResponse.fromJson(data, ReportSummaryResponse.fromJson);
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
