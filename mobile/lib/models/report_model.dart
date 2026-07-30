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
      dataJson: dataJson ?? Map<String, dynamic>.from(this.dataJson),
      currentStep: currentStep ?? this.currentStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
      dataJson: json['data_json'] is String
          ? jsonDecode(json['data_json'] as String) as Map<String, dynamic>
          : (json['data_json'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      currentStep: json['current_step'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
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
      'data_json': dataJson,
      'current_step': currentStep,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
