import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/login_request.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_cubit.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required AuthRepository authRepository,
    required AuthCubit authCubit,
  }) : _authRepository = authRepository,
       _authCubit = authCubit,
       super(const LoginState.initial());

  final AuthRepository _authRepository;
  final AuthCubit _authCubit;

  Future<void> submit(LoginRequest request) async {
    if (state.isSubmitting) {
      return;
    }

    emit(const LoginState.submitting());
    try {
      final session = await _authRepository.login(request);
      _authCubit.setAuthenticated(session.user);
      emit(const LoginState.success());
    } catch (error) {
      emit(LoginState.failure(_friendlyMessage(error)));
    }
  }

  String _friendlyMessage(Object error) {
    if (error is ApiException) {
      return switch (error.kind) {
        ApiErrorKind.unauthorized => 'Invalid email or password.',
        ApiErrorKind.forbidden => error.message,
        ApiErrorKind.timeout => 'Request timed out. Please try again.',
        ApiErrorKind.network =>
          'No network connection. Check your backend URL.',
        ApiErrorKind.badRequest => error.message,
        ApiErrorKind.notFound => error.message,
        ApiErrorKind.conflict => error.message,
        ApiErrorKind.server => 'The server is unavailable right now.',
        ApiErrorKind.invalidResponse =>
          'The server returned an invalid response. Please try again.',
        ApiErrorKind.unknown => 'Unable to sign in right now.',
      };
    }
    return 'Unable to sign in right now.';
  }
}
