import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';

enum EditProfileStatus { initial, submitting, success, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.errorMessage,
    this.errorKind,
  });

  final EditProfileStatus status;
  final String? errorMessage;
  final ApiErrorKind? errorKind;

  bool get isSubmitting => status == EditProfileStatus.submitting;

  EditProfileState copyWith({
    EditProfileStatus? status,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, errorKind];
}

const _unchanged = Object();
