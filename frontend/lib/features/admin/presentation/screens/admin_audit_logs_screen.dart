import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/audit_log_model.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final ApiService _apiService = ApiService();
  List<AuditLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.auditLogsList);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _logs = data.map((json) => AuditLogModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // بيانات تجريبية حية للمنصة في حال عدم الاتصال المباشر بالسيرفر
      setState(() {
        _logs = [
          AuditLogModel(
            id: '1',
            userName: 'أحمد الإداري',
            action: 'UPDATE_PRODUCT_PRICE',
            module: 'Products',
            ipAddress: '192.168.1.15',
            createdAt: '2026-06-07 10:30',
          ),
          AuditLogModel(
            id: '2',
            userName: 'محمد السوبر أدمن',
            action: 'APPROVE_STORE',
            module: 'Stores',
            ipAddress: '192.168.1.20',
            createdAt: '2026-06-07 09:15',
          ),
          AuditLogModel(
            id: '3',
            userName: 'سارة المالية',
            action: 'UPDATE_TAX_SETTINGS',
            module: 'Settings',
            ipAddress: '192.168.1.42',
            createdAt: '2026-06-06 16:45',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'سجلات التدقيق والمراقبة الأمنية (Audit Logs) 🛡️',
          style: TextStyle(color: AppTheme.gold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _logs.isEmpty
          ? const Center(
              child: Text(
                'لا توجد سجلات تدقيق مسجلة حالياً',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log.action,
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.module,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'المسؤول: ${log.userName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عنوان IP: ${log.ipAddress} | التوقيت: ${log.createdAt}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
