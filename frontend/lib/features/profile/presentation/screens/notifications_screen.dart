import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // قائمة الإشعارات الحقيقية التفاعلية
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': '📦 تحديث حالة الطلب #SOQ-9021',
      'body': 'تم توصيل طلبك بنجاح. شكراً لتسوقك معنا في سوق جو!',
      'time': 'منذ ساعتين',
      'isRead': false,
    },
    {
      'title': '🎟️ كوبون خصم جديد بانتظارك',
      'body': 'استخدم الكود SOUQ20 واحصل على خصم 20% على الملابس الشتوية.',
      'time': 'أمس',
      'isRead': true,
    },
    {
      'title': '✨ تم تفعيل غرفة القياس بالذكاء الاصطناعي',
      'body':
          'تم تحديث مقاساتك الذكية بنجاح، يمكنك الآن تجربة الملابس افتراضياً.',
      'time': 'منذ 3 أيام',
      'isRead': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم تعيين كافة الإشعارات كمقروءة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '🔔 مركز الإشعارات والتنبيهات',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.gold),
            tooltip: 'قراءة الكل',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'لا توجد إشعارات جديدة حالياً 📭',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                bool isRead = notif['isRead'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceDark.withAlpha(220),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRead
                          ? Colors.white10
                          : AppTheme.gold.withAlpha(150),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'],
                              style: TextStyle(
                                color: isRead ? Colors.white70 : AppTheme.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            notif['time'],
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['body'],
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
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
