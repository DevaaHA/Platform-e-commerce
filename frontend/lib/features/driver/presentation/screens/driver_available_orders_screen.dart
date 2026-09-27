import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/delivery_model.dart';

class DriverAvailableOrdersScreen extends StatefulWidget {
  const DriverAvailableOrdersScreen({super.key});

  @override
  State<DriverAvailableOrdersScreen> createState() =>
      _DriverAvailableOrdersScreenState();
}

class _DriverAvailableOrdersScreenState
    extends State<DriverAvailableOrdersScreen> {
  final ApiService _apiService = ApiService();
  List<DeliveryModel> _availableOrders = [];
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
          _availableOrders = data
              .map((json) => DeliveryModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await _apiService.post(ApiConstants.driverAcceptOrder(orderId), data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب بنجاح! توجه إلى المتجر للاستلام 🚀'),
        ),
      );
      _fetchAvailableOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، قد يكون الطلب قُبل من كابتن آخر')),
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
          : _availableOrders.isEmpty
          ? const Center(
              child: Text(
                'لا توجد طلبات متاحة للتوصيل حالياً',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableOrders.length,
              itemBuilder: (context, index) {
                final delivery = _availableOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween, // التصحيح هنا
                        children: [
                          Text(
                            'المتجر: ${delivery.storeName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${delivery.amount} د.أ',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عنوان التوصيل: ${delivery.customerAddress}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المسافة المقدرة: ${delivery.distance} كم',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: AppTheme.darkBg,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _acceptOrder(delivery.orderId),
                          child: const Text(
                            'قبول الطلب وبدء التوصيل',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
