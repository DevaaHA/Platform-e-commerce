import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/notification_model.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.notificationsList);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _notifications = data
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _apiService.patch(ApiConstants.notificationRead(id), data: {});
      _fetchNotifications();
    } catch (e) {
      // التعامل مع الخطأ بصمت أو إشعار خفيف
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _apiService.delete(ApiConstants.notificationDelete(id));
      _fetchNotifications();
    } catch (e) {
      // التعامل مع الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'مركز الإشعارات 🔔',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _notifications.isEmpty
          ? const Center(
              child: Text(
                'ليس لديك أي إشعارات جديدة',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isRead
                          ? Colors.white10
                          : AppTheme.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: AppTheme.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.isRead
                                    ? AppTheme.white
                                    : AppTheme.gold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.createdAt,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (!item.isRead)
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.gold,
                                size: 20,
                              ),
                              onPressed: () => _markAsRead(item.id),
                              tooltip: 'تحديد كمقروء',
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => _deleteNotification(item.id),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
