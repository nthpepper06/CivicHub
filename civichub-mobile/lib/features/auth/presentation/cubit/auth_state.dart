import 'package:equatable/equatable.dart';

import '../../domain/models/citizen_profile.dart';

enum AuthStatus { unknown, checking, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({required this.status, this.user, this.message});

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.checking() : this(status: AuthStatus.checking);
  const AuthState.authenticated(CitizenProfile user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.failure(String message)
    : this(status: AuthStatus.failure, message: message);

  final AuthStatus status;
  final CitizenProfile? user;
  final String? message;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.checking;

  @override
  List<Object?> get props => [status, user, message];
}
