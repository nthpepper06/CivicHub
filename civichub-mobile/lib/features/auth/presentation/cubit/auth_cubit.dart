import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/unauthorized_handler.dart';
import '../../domain/models/citizen_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> implements UnauthorizedHandler {
  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.unknown());

  final AuthRepository _authRepository;

  Future<void> bootstrap() async {
    emit(const AuthState.checking());
    try {
      final user = await _authRepository.bootstrapSession();
      if (user == null) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.authenticated(user));
      }
    } on ApiException catch (error) {
      if (_isSessionInvalid(error)) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.failure(_friendlyBootstrapMessage(error)));
      }
    } catch (_) {
      emit(const AuthState.failure('Unable to verify your session right now.'));
    }
  }

  void setAuthenticated(CitizenProfile user) {
    emit(AuthState.authenticated(user));
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> handleUnauthorized() async {
    await logout();
  }

  bool _isSessionInvalid(ApiException error) {
    return error.kind == ApiErrorKind.unauthorized ||
        error.kind == ApiErrorKind.forbidden ||
        error.kind == ApiErrorKind.invalidResponse;
  }

  String _friendlyBootstrapMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot reach the backend right now. Check your connection and try again.',
      ApiErrorKind.timeout => 'Session check timed out. Please try again.',
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => 'Unable to verify your session right now.',
      ApiErrorKind.unauthorized ||
      ApiErrorKind.forbidden ||
      ApiErrorKind.invalidResponse => error.message,
    };
  }
}
