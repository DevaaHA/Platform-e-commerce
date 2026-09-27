import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AdminDeliverySettingsScreen extends StatefulWidget {
  const AdminDeliverySettingsScreen({super.key});

  @override
  State<AdminDeliverySettingsScreen> createState() =>
      _AdminDeliverySettingsScreenState();
}

class _AdminDeliverySettingsScreenState
    extends State<AdminDeliverySettingsScreen> {
  final ApiService _apiService = ApiService();
  final _feeController = TextEditingController(text: '1.5');
  final _thresholdController = TextEditingController(text: '50.0');
  bool _isLoading = false;

  Future<void> _saveDeliverySettings() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.patch(
        ApiConstants.deliverySettings,
        data: {
          'base_fee': double.tryParse(_feeController.text) ?? 1.5,
          'free_threshold': double.tryParse(_thresholdController.text) ?? 50.0,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث إعدادات التوصيل وحفظها بنجاح 🚚'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حفظ إعدادات التوصيل')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إعدادات التوصيل ورسوم الشحن 🛵',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              'رسوم التوصيل الأساسية (Base Fee - JOD)',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: '1.5',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الحد الأدنى للتوصيل المجاني (Free Delivery Above - JOD)',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: '50.0',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.darkBg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _saveDeliverySettings,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBg,
                        ),
                      )
                    : const Text(
                        'حفظ إعدادات التوصيل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
