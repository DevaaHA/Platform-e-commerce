import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrdersHistoryScreen extends StatelessWidget {
  final String? statusFilter; // استقبال فلتر الحالة من شاشة الملف الشخصي

  const OrdersHistoryScreen({super.key, this.statusFilter});

  @override
  Widget build(BuildContext context) {
    // قائمة طلبات شاملة ومتنوعة الحالات لتجربة مستخدم حقيقية
    final List<Map<String, dynamic>> allOrders = [
      {
        'id': '#SOQ-9200',
        'date': '2026-09-04',
        'total': '15.00 د.أ',
        'statusKey': 'pending_payment',
        'statusText': 'بانتظار الدفع 💳',
        'statusColor': Colors.orangeAccent,
      },
      {
        'id': '#SOQ-9150',
        'date': '2026-09-02',
        'total': '60.00 د.أ',
        'statusKey': 'processing',
        'statusText': 'قيد التجهيز 📦',
        'statusColor': Colors.amber,
      },
      {
        'id': '#SOQ-8843',
        'date': '2026-08-12',
        'total': '25.50 د.أ',
        'statusKey': 'shipped',
        'statusText': 'جاري الشحن 🚚',
        'statusColor': Colors.blueAccent,
      },
      {
        'id': '#SOQ-9021',
        'date': '2026-08-20',
        'total': '45.00 د.أ',
        'statusKey': 'delivered_pending_review',
        'statusText': 'بانتظار التقييم ⭐',
        'statusColor': Colors.purpleAccent,
      },
    ];

    // تصفية الطلبات بناءً على الضغط في واجهة البروفايل، أو عرض الكل إذا لم يتم تحديد فلتر
    final displayedOrders = statusFilter == null
        ? allOrders
        : allOrders
              .where((order) => order['statusKey'] == statusFilter)
              .toList();

    String getTitle() {
      switch (statusFilter) {
        case 'pending_payment':
          return '💳 طلبات بانتظار الدفع';
        case 'processing':
          return '📦 طلبات قيد التجهيز';
        case 'shipped':
          return '🚚 طلبات جاري شحنها';
        case 'delivered_pending_review':
          return '⭐ طلبات بانتظار التقييم';
        default:
          return '📦 سجل الطلبات السابقة';
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          getTitle(),
          style: const TextStyle(
            color: AppTheme.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: displayedOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 60,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لا توجد طلبات مطابقة لهذه الحالة حالياً 📭',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayedOrders.length,
              itemBuilder: (context, index) {
                final order = displayedOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['id'],
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'التاريخ: ${order['date']}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (order['statusColor'] as Color).withAlpha(
                                30,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: order['statusColor']),
                            ),
                            child: Text(
                              order['statusText'],
                              style: TextStyle(
                                color: order['statusColor'],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order['total'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white24,
                            size: 14,
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
