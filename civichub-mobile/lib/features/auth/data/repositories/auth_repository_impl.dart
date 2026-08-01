import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/auth_token_storage.dart';
import '../../data/models/login_request.dart';
import '../../data/models/profile_update_request.dart';
import '../../data/models/change_password_request.dart';
import '../../domain/models/auth_enums.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/citizen_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthTokenStorage tokenStorage,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthTokenStorage _tokenStorage;

  @override
  Future<AuthSession> login(LoginRequest request) async {
    try {
      final response = await _remoteDataSource.login(request);
      _ensureUsableToken(response.accessToken);
      _ensureValidProfile(response.user);
      _ensureSupportedAppRole(response.user);
      await _tokenStorage.saveAccessToken(response.accessToken);
      return response.toSession();
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.forbidden) {
        await _tokenStorage.deleteAccessToken();
      }
      rethrow;
    }
  }

  @override
  Future<CitizenProfile?> bootstrapSession() async {
    if (!await _tokenStorage.hasAccessToken()) {
      return null;
    }

    try {
      final user = await _remoteDataSource.getCurrentUser();
      _ensureValidProfile(user);
      _ensureSupportedAppRole(user);
      return user;
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized ||
          error.kind == ApiErrorKind.forbidden) {
        await _tokenStorage.deleteAccessToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CitizenProfile> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      _ensureValidProfile(user);
      _ensureSupportedAppRole(user);
      return user;
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized ||
          error.kind == ApiErrorKind.forbidden) {
        await _tokenStorage.deleteAccessToken();
      }
      rethrow;
    }
  }

  @override
  Future<CitizenProfile> updateCurrentUser(ProfileUpdateRequest request) async {
    try {
      final user = await _remoteDataSource.updateCurrentUser(request);
      _ensureValidProfile(user);
      _ensureSupportedAppRole(user);
      return user;
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized ||
          error.kind == ApiErrorKind.forbidden) {
        await _tokenStorage.deleteAccessToken();
      }
      rethrow;
    }
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _remoteDataSource.changePassword(request);
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized ||
          error.kind == ApiErrorKind.forbidden) {
        await _tokenStorage.deleteAccessToken();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.deleteAccessToken();
  }

  @override
  Future<bool> hasStoredToken() {
    return _tokenStorage.hasAccessToken();
  }

  void _ensureSupportedAppRole(CitizenProfile user) {
    if (user.role == UserRole.admin) {
      throw ApiException.forbidden.copyWith(
        message: 'Admin accounts must use the CivicHub admin console.',
      );
    }
  }

  void _ensureUsableToken(String token) {
    if (token.trim().isEmpty) {
      throw ApiException.invalidResponse;
    }
  }

  void _ensureValidProfile(CitizenProfile user) {
    if (user.id == null || user.email.trim().isEmpty) {
      throw ApiException.invalidResponse;
    }
  }
}
