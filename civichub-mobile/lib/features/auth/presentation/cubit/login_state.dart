import 'package:equatable/equatable.dart';

enum LoginStatus { initial, submitting, success, failure }

class LoginState extends Equatable {
  const LoginState({required this.status, this.errorMessage});

  const LoginState.initial() : this(status: LoginStatus.initial);
  const LoginState.submitting() : this(status: LoginStatus.submitting);
  const LoginState.success() : this(status: LoginStatus.success);
  const LoginState.failure(String message)
    : this(status: LoginStatus.failure, errorMessage: message);

  final LoginStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == LoginStatus.submitting;

  @override
  List<Object?> get props => [status, errorMessage];
}
