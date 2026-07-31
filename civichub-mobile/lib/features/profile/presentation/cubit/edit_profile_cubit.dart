import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/data/models/profile_update_request.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit({
    required AuthRepository authRepository,
    required AuthCubit authCubit,
  }) : _authRepository = authRepository,
       _authCubit = authCubit,
       super(const EditProfileState());

  final AuthRepository _authRepository;
  final AuthCubit _authCubit;

  Future<void> submit(ProfileUpdateRequest request) async {
    if (state.isSubmitting) {
      return;
    }

    emit(const EditProfileState(status: EditProfileStatus.submitting));

    try {
      final user = await _authRepository.updateCurrentUser(request);
      _authCubit.setAuthenticated(user);
      emit(const EditProfileState(status: EditProfileStatus.success));
    } on ApiException catch (error) {
      emit(
        EditProfileState(
          status: EditProfileStatus.failure,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        EditProfileState(
          status: EditProfileStatus.failure,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot update your profile right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Updating your profile timed out. Please try again.',
      ApiErrorKind.badRequest => error.message,
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.notFound => 'Your profile could not be found.',
      ApiErrorKind.conflict => error.message,
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Your updated profile could not be read from the server response.',
      ApiErrorKind.unknown => error.message,
    };
  }
}
