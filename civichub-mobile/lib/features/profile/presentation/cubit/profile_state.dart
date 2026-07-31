import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/models/citizen_profile.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.isRefreshing = false,
    this.errorMessage,
    this.errorKind,
  });

  final ProfileStatus status;
  final CitizenProfile? user;
  final bool isRefreshing;
  final String? errorMessage;
  final ApiErrorKind? errorKind;

  bool get isInitialLoading =>
      status == ProfileStatus.loading && user == null && !isRefreshing;

  ProfileState copyWith({
    ProfileStatus? status,
    Object? user = _unchanged,
    bool? isRefreshing,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user == _unchanged ? this.user : user as CitizenProfile?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isRefreshing,
    errorMessage,
    errorKind,
  ];
}

const _unchanged = Object();
