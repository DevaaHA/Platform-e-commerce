import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/order_model.dart';

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  final ApiService _apiService = ApiService();
  List<OrderModel> _storeOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreOrders();
  }

  Future<void> _fetchStoreOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.storeOrders);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _storeOrders = data.map((json) => OrderModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String id) async {
    try {
      await _apiService.patch(ApiConstants.acceptStoreOrder(id), data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الطلب وبدء مرحلة التجهيز 🚀')),
      );
      _fetchStoreOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل قبول الطلب')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إدارة طلبات المتجر (Store Orders)',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _storeOrders.isEmpty
          ? const Center(
              child: Text(
                'لا توجد طلبات جديدة في المتجر',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _storeOrders.length,
              itemBuilder: (context, index) {
                final order = _storeOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الإجمالي: ${order.total} د.أ | الحالة: ${order.status}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.status == 'Pending')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: AppTheme.darkBg,
                          ),
                          onPressed: () => _acceptOrder(order.id),
                          child: const Text('قبول الطلب'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
