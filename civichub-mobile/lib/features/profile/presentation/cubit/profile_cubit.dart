import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/models/citizen_profile.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthRepository authRepository,
    required AuthCubit authCubit,
    CitizenProfile? initialUser,
  }) : _authRepository = authRepository,
       _authCubit = authCubit,
       super(
         ProfileState(
           status: initialUser == null
               ? ProfileStatus.initial
               : ProfileStatus.success,
           user: initialUser,
         ),
       );

  final AuthRepository _authRepository;
  final AuthCubit _authCubit;

  Future<void> load() async {
    if (state.status == ProfileStatus.loading && state.user == null) {
      return;
    }
    await _load(refreshing: false);
  }

  Future<void> retry() async {
    await _load(refreshing: false);
  }

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }
    await _load(refreshing: true);
  }

  Future<void> _load({required bool refreshing}) async {
    emit(
      state.copyWith(
        status: refreshing ? state.status : ProfileStatus.loading,
        isRefreshing: refreshing,
        errorMessage: null,
        errorKind: null,
      ),
    );

    try {
      final user = await _authRepository.getCurrentUser();
      _authCubit.setAuthenticated(user);
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          user: user,
          isRefreshing: false,
          errorMessage: null,
          errorKind: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          isRefreshing: false,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          isRefreshing: false,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load your profile right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Loading your profile timed out. Please try again.',
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.notFound => 'Your profile could not be found.',
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Your profile could not be read from the server response.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
