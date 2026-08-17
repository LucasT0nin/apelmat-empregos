class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.accountType,
    required this.isVerified,
    required this.isStaff,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      displayName: json['display_name'] as String,
      accountType: json['account_type'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String phone;
  final String displayName;
  final String accountType;
  final bool isVerified;
  final bool isStaff;

  bool get canWork => !isStaff && accountType == 'professional';
  bool get canHire => !isStaff && accountType == 'contractor';
}
