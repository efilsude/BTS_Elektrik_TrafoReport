class User {
  final String id;
  final String fullName;
  final String? email;
  final String phone;
  final String? sicilNo;
  final String? operatorTitle;
  final String? ekipnetNo;
  final String? diplomaNo;
  final String? signaturePath;
  final String role; // 'admin' or 'employee'
  final bool isActive;
  final bool hasSignature;

  User({
    required this.id,
    required this.fullName,
    this.email,
    required this.phone,
    this.sicilNo,
    this.operatorTitle,
    this.ekipnetNo,
    this.diplomaNo,
    this.signaturePath,
    required this.role,
    required this.isActive,
    this.hasSignature = false,
  });

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  static bool _parseBool(dynamic value, {bool defaultValue = true}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int || value is double) return value != 0;
    if (value is String) {
      final String lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final String? sigPath = json['signature_path']?.toString() ?? json['signaturePath']?.toString();
    final dynamic sigValue = json['has_signature'] ?? json['hasSignature'];
    final bool hasSig = (sigPath != null && sigPath.trim().isNotEmpty) ||
        _parseBool(sigValue, defaultValue: false);

    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      sicilNo: json['sicil_no']?.toString() ?? json['sicilNo']?.toString(),
      operatorTitle: json['operator_title']?.toString() ?? json['operatorTitle']?.toString() ?? json['title']?.toString(),
      ekipnetNo: json['ekipnet_no']?.toString() ?? json['ekipnetNo']?.toString(),
      diplomaNo: json['diploma_no']?.toString() ?? json['diplomaNo']?.toString(),
      signaturePath: sigPath,
      role: json['role']?.toString() ?? 'employee',
      isActive: _parseBool(json['is_active'] ?? json['isActive'], defaultValue: true),
      hasSignature: hasSig,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'sicil_no': sicilNo,
      'operator_title': operatorTitle,
      'ekipnet_no': ekipnetNo,
      'diploma_no': diplomaNo,
      'signature_path': signaturePath,
      'role': role,
      'is_active': isActive,
      'has_signature': hasSignature,
    };
  }
}
