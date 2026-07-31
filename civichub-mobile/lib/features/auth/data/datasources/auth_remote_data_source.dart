import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/profile_update_request.dart';
import '../models/change_password_request.dart';
import '../../domain/models/citizen_profile.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<CitizenProfile> getCurrentUser();
  Future<CitizenProfile> updateCurrentUser(ProfileUpdateRequest request);
  Future<void> changePassword(ChangePasswordRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: request.toJson(),
        options: Options(extra: {ApiClient.requiresAuthExtraKey: false}),
      );
      final data = _responseData(response.data);
      return LoginResponse.fromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    }
  }

  @override
  Future<CitizenProfile> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.authMe,
      );
      final data = _responseData(response.data);
      return citizenProfileFromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    }
  }

  @override
  Future<CitizenProfile> updateCurrentUser(ProfileUpdateRequest request) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.authMe,
        data: request.toJson(),
      );
      final data = _responseData(response.data);
      return citizenProfileFromJson(data);
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.authChangePassword,
        data: request.toJson(),
      );
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    }
  }

  Map<String, dynamic> _responseData(Map<String, dynamic>? responseBody) {
    final data = responseBody?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException.invalidResponse;
  }
}
