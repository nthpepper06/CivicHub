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
}
