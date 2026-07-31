import '../models/auth_session.dart';
import '../models/citizen_profile.dart';
import '../../data/models/change_password_request.dart';
import '../../data/models/login_request.dart';
import '../../data/models/profile_update_request.dart';

abstract class AuthRepository {
  Future<AuthSession> login(LoginRequest request);
  Future<CitizenProfile?> bootstrapSession();
  Future<CitizenProfile> getCurrentUser();
  Future<CitizenProfile> updateCurrentUser(ProfileUpdateRequest request);
  Future<void> changePassword(ChangePasswordRequest request);
  Future<void> logout();
  Future<bool> hasStoredToken();
}
