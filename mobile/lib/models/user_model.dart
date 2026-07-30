class User {
  final String id;
  final String fullName;
  final String? email;
  final String phone;
  final String? sicilNo;
  final String role; // 'admin' or 'employee'
  final bool isActive;

  User({
    required this.id,
    required this.fullName,
    this.email,
    required this.phone,
    this.sicilNo,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      sicilNo: json['sicil_no'] ?? json['sicilNo'],
      role: json['role'] ?? 'employee',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'sicil_no': sicilNo,
      'role': role,
      'is_active': isActive,
    };
  }
}
