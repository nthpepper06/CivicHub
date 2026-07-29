enum UserRole { citizen, staff, admin }

enum UserStatus { active, inactive, blocked }

UserRole? userRoleFromJson(String? value) {
  return switch (value?.toUpperCase()) {
    'CITIZEN' => UserRole.citizen,
    'STAFF' => UserRole.staff,
    'ADMIN' => UserRole.admin,
    _ => null,
  };
}

UserStatus? userStatusFromJson(String? value) {
  return switch (value?.toUpperCase()) {
    'ACTIVE' => UserStatus.active,
    'INACTIVE' => UserStatus.inactive,
    'BLOCKED' => UserStatus.blocked,
    _ => null,
  };
}

String userRoleToJson(UserRole role) {
  return switch (role) {
    UserRole.citizen => 'CITIZEN',
    UserRole.staff => 'STAFF',
    UserRole.admin => 'ADMIN',
  };
}

String userStatusToJson(UserStatus status) {
  return switch (status) {
    UserStatus.active => 'ACTIVE',
    UserStatus.inactive => 'INACTIVE',
    UserStatus.blocked => 'BLOCKED',
  };
}
