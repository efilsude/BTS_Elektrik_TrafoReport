import 'dart:convert';

class Report {
  final String id;
  final String title;
  final String reportType; // 'bakim' or 'test'
  final String subType; // 'normal' or 'kesici'
  final String transformerType; // 'hermetik', 'kuru_tip', 'gt'
  final String customerName;
  final String trafoLabel;
  final String status; // 'draft' or 'final'
  final String? creatorDisplayName;
  final Map<String, dynamic> dataJson;
  final int currentStep;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.title,
    required this.reportType,
    required this.subType,
    required this.transformerType,
    required this.customerName,
    required this.trafoLabel,
    required this.status,
    this.creatorDisplayName,
    required this.dataJson,
    required this.currentStep,
    required this.createdAt,
    required this.updatedAt,
  });

  Report copyWith({
    String? id,
    String? title,
    String? reportType,
    String? subType,
    String? transformerType,
    String? customerName,
    String? trafoLabel,
    String? status,
    String? creatorDisplayName,
    Map<String, dynamic>? dataJson,
    int? currentStep,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      reportType: reportType ?? this.reportType,
      subType: subType ?? this.subType,
      transformerType: transformerType ?? this.transformerType,
      customerName: customerName ?? this.customerName,
      trafoLabel: trafoLabel ?? this.trafoLabel,
      status: status ?? this.status,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      dataJson: dataJson ?? Map<String, dynamic>.from(this.dataJson),
      currentStep: currentStep ?? this.currentStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDateTime(dynamic input) {
    if (input == null) return DateTime.now();
    if (input is DateTime) return input;
    final String str = input.toString().trim();
    if (str.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(str);
    } catch (_) {
      try {
        if (str.contains('.')) {
          final List<String> parts = str.split('.');
          if (parts.length == 3) {
            final int p1 = int.parse(parts[0]);
            final int p2 = int.parse(parts[1]);
            final int p3 = int.parse(parts[2]);
            if (p3 > 1000) {
              return DateTime(p3, p2, p1);
            } else if (p1 > 1000) {
              return DateTime(p1, p2, p3);
            }
          }
        }
      } catch (_) {}
    }
    return DateTime.now();
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      reportType: json['report_type'] ?? 'bakim',
      subType: json['sub_type'] ?? 'normal',
      transformerType: json['transformer_type'] ?? 'hermetik',
      customerName: json['customer_name'] ?? '',
      trafoLabel: json['trafo_label'] ?? '',
      status: json['status'] ?? 'draft',
      creatorDisplayName: json['creator_display_name'] ?? json['creatorDisplayName'],
      dataJson: json['data_json'] is String
          ? jsonDecode(json['data_json'] as String) as Map<String, dynamic>
          : (json['data_json'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      currentStep: json['current_step'] ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'report_type': reportType,
      'sub_type': subType,
      'transformer_type': transformerType,
      'customer_name': customerName,
      'trafo_label': trafoLabel,
      'status': status,
      'creator_display_name': creatorDisplayName,
      'data_json': dataJson,
      'current_step': currentStep,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
