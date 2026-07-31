import '../../../../core/network/api_exception.dart';
import '../../domain/models/auth_enums.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/citizen_profile.dart';

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final CitizenProfile user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = _requiredNonBlankString(json, 'accessToken');
    final userJson = _requiredMap(json, 'user');

    return LoginResponse(
      accessToken: accessToken,
      tokenType: _optionalNonBlankString(json, 'tokenType') ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: citizenProfileFromJson(userJson),
    );
  }

  AuthSession toSession() {
    return AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      user: user,
    );
  }
}

CitizenProfile citizenProfileFromJson(Map<String, dynamic> json) {
  final role = userRoleFromJson(_requiredNonBlankString(json, 'role'));
  if (role == null) {
    throw ApiException.invalidResponse;
  }

  final statusValue = json['status'];
  final status = statusValue is String && statusValue.trim().isNotEmpty
      ? userStatusFromJson(statusValue)
      : UserStatus.active;
  if (status == null) {
    throw ApiException.invalidResponse;
  }

  return CitizenProfile(
    id: _requiredInt(json, 'id'),
    fullName: _optionalNonBlankString(json, 'fullName') ?? '',
    email: _requiredNonBlankString(json, 'email'),
    phone: _optionalNonBlankString(json, 'phone'),
    avatar: _optionalNonBlankString(json, 'avatar'),
    role: role,
    status: status,
    isActive: json['isActive'] as bool? ?? false,
    departmentId: _optionalInt(json, 'departmentId'),
    departmentName: _optionalNonBlankString(json, 'departmentName'),
    createdAt: _optionalDateTime(json, 'createdAt'),
    updatedAt: _optionalDateTime(json, 'updatedAt'),
  );
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw ApiException.invalidResponse;
}

String _requiredNonBlankString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw ApiException.invalidResponse;
}

String? _optionalNonBlankString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toInt();
  }
  throw ApiException.invalidResponse;
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is num ? value.toInt() : null;
}

DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
