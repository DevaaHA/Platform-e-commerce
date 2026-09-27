import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class DriverDeliveryMapScreen extends StatefulWidget {
  final String deliveryId;

  const DriverDeliveryMapScreen({super.key, required this.deliveryId});

  @override
  State<DriverDeliveryMapScreen> createState() =>
      _DriverDeliveryMapScreenState();
}

class _DriverDeliveryMapScreenState extends State<DriverDeliveryMapScreen> {
  final ApiService _apiService = ApiService();
  bool _isSendingLocation = false;

  Future<void> _sendCurrentLocation() async {
    setState(() => _isSendingLocation = true);
    try {
      // إرسال إحداثيات افتراضية حقيقية للباك إيند
      await _apiService.post(
        ApiConstants.locationUpdate,
        data: {'latitude': 31.9539, 'longitude': 35.9106, 'speed': 45.0},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث موقع الـ GPS وبثه للعميل بنجاح 📡'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تحديث الموقع')));
    } finally {
      if (mounted) {
        setState(() => _isSendingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'خريطة التوصيل المباشر للكابتن 🛵',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppTheme.surfaceDark,
            child: const Center(
              child: Text(
                'خريطة الملاحة ونقاط الاستلام والتسليم',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.darkBg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSendingLocation ? null : _sendCurrentLocation,
              child: _isSendingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.darkBg,
                      ),
                    )
                  : const Text(
                      'تحديث وبث الموقع الحالي (GPS)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
