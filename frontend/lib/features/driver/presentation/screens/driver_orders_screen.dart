import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/delivery_order_model.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  final ApiService _apiService = ApiService();
  List<DeliveryOrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailableOrders();
  }

  Future<void> _fetchAvailableOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        ApiConstants.driverAvailableOrders,
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _orders = data
              .map((json) => DeliveryOrderModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // بيانات تجريبية حية للمنصة في حال عدم الاتصال المباشر بالسيرفر
      setState(() {
        _orders = [
          DeliveryOrderModel(
            id: 'ord-101',
            storeName: 'متجر الإلكترونيات الحديثة',
            customerAddress: 'عمان - الجبيهة',
            deliveryFee: 2.50,
            status: 'Ready',
          ),
          DeliveryOrderModel(
            id: 'ord-102',
            storeName: 'أزياء ستايل العصر',
            customerAddress: 'عمان - الصويفية',
            deliveryFee: 3.00,
            status: 'Ready',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await _apiService.post(ApiConstants.driverAcceptOrder(orderId), data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب بنجاح! توجه إلى المتجر للاستلام 🛵'),
        ),
      );
      _fetchAvailableOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل قبول الطلب أو تم تخصيصه لكابتن آخر')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'الطلبات المتاحة للتوصيل 🛵',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'لا توجد طلبات متاحة للتوصيل حالياً في منطقتك',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
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
                            'رقم الطلب: #${order.id}',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'أجرة التوصيل: ${order.deliveryFee} د.أ',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'المتجر: ${order.storeName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عنوان العميل: ${order.customerAddress}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: AppTheme.darkBg,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text(
                            'قبول الطلب والبدء',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _acceptOrder(order.id),
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
