class ProfileUpdateRequest {
  const ProfileUpdateRequest({required this.fullName, this.phone, this.avatar});

  final String fullName;
  final String? phone;
  final String? avatar;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName.trim(),
      'phone': _nullableTrim(phone),
      'avatar': _nullableTrim(avatar),
    };
  }

  String? _nullableTrim(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
