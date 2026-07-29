import '../models/auth_session.dart';
import '../models/citizen_profile.dart';
import '../../data/models/login_request.dart';

abstract class AuthRepository {
  Future<AuthSession> login(LoginRequest request);
  Future<CitizenProfile?> bootstrapSession();
  Future<CitizenProfile> getCurrentUser();
  Future<void> logout();
  Future<bool> hasStoredToken();
}
