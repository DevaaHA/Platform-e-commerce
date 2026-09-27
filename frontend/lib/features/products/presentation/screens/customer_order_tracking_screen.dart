import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const CustomerOrderTrackingScreen({super.key, required this.orderId});

  @override
  State<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState
    extends State<CustomerOrderTrackingScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _trackingData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrackingInfo();
  }

  Future<void> _fetchTrackingInfo() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        ApiConstants.trackingSession(widget.orderId),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _trackingData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'تتبع الطلب لحظياً 🗺️',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Stack(
              children: [
                // محاكاة الخريطة التفاعلية (مكان Google Maps Widget)
                Container(
                  color: AppTheme.surfaceDark,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 80, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'جاري عرض خريطة التتبع المباشر للطلب...',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                // بطاقة معلومات الكابتن والوقت المتوقع للوصول (ETA) أسفل الشاشة
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الوقت المتوقع للوصول (ETA):',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _trackingData['eta'] ?? '10 دقائق',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.gold,
                              child: Icon(Icons.person, color: AppTheme.darkBg),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _trackingData['driver_name'] ??
                                        'الكابتن المحترف',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _trackingData['vehicle_info'] ??
                                        'تويوتا - رقم اللوحة: 1234',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: AppTheme.gold,
                                size: 28,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('جاري الاتصال بالكابتن...'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
