import 'auth_enums.dart';

class CitizenProfile {
  const CitizenProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.role,
    required this.status,
    required this.isActive,
    required this.departmentId,
    required this.departmentName,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;
  final UserRole role;
  final UserStatus status;
  final bool isActive;
  final int? departmentId;
  final String? departmentName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first.isEmpty ? '?' : words.first[0].toUpperCase();
    }
    final first = words.first.isEmpty ? '?' : words.first[0].toUpperCase();
    final last = words.last.isEmpty ? '?' : words.last[0].toUpperCase();
    return '$first$last';
  }

  CitizenProfile copyWith({
    int? id,
    String? fullName,
    String? email,
    Object? phone = _unchanged,
    Object? avatar = _unchanged,
    UserRole? role,
    UserStatus? status,
    bool? isActive,
    Object? departmentId = _unchanged,
    Object? departmentName = _unchanged,
    Object? createdAt = _unchanged,
    Object? updatedAt = _unchanged,
  }) {
    return CitizenProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone == _unchanged ? this.phone : phone as String?,
      avatar: avatar == _unchanged ? this.avatar : avatar as String?,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      departmentId: departmentId == _unchanged
          ? this.departmentId
          : departmentId as int?,
      departmentName: departmentName == _unchanged
          ? this.departmentName
          : departmentName as String?,
      createdAt: createdAt == _unchanged
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: updatedAt == _unchanged
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }
}

const _unchanged = Object();
