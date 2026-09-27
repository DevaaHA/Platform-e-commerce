class AuditLogModel {
  final String id;
  final String userName;
  final String action;
  final String module;
  final String ipAddress;
  final String createdAt;

  AuditLogModel({
    required this.id,
    required this.userName,
    required this.action,
    required this.module,
    required this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      userName: json['user_name'] ?? 'مدير النظام',
      action: json['action'] ?? 'UPDATE',
      module: json['module'] ?? 'Products',
      ipAddress: json['ip_address'] ?? '127.0.0.1',
      createdAt: json['created_at'] ?? '',
    );
  }
}
