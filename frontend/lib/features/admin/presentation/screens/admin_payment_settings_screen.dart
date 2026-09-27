import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AdminPaymentSettingsScreen extends StatefulWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  State<AdminPaymentSettingsScreen> createState() =>
      _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState
    extends State<AdminPaymentSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _cashOnDelivery = true;
  bool _creditCard = true;
  bool _wallet = true;
  bool _isLoading = false; // تم استخدامه فعلياً في الواجهة لتجنب التحذير

  Future<void> _updatePaymentSettings() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.patch(
        ApiConstants.paymentSettings,
        data: {
          'cash_on_delivery': _cashOnDelivery,
          'credit_card': _creditCard,
          'wallet': _wallet,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث طرق الدفع وتطبيقها في المنصة بنجاح 💳'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حفظ إعدادات الدفع')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إدارة بوابات وطرق الدفع 💳',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  'التحكم الفوري بطرق الدفع المتاحة لعملاء منصة سوق جو:',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'الدفع عند الاستلام (Cash On Delivery)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'السماح للعملاء بالدفع نقداً عند استلاستم الطلب',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _cashOnDelivery,
                  activeThumbColor: AppTheme.gold,
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          setState(() => _cashOnDelivery = val);
                          _updatePaymentSettings();
                        },
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  title: const Text(
                    'البطاقات الائتمانية (Credit Card / Online)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'الدفع الإلكتروني الآمن عبر البوابة البنكية',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _creditCard,
                  activeThumbColor: AppTheme.gold,
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          setState(() => _creditCard = val);
                          _updatePaymentSettings();
                        },
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  title: const Text(
                    'المحفظة الإلكترونية (SouqJo Wallet)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'الخصم المباشر من رصيد محفظة العميل',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _wallet,
                  activeThumbColor: AppTheme.gold,
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          setState(() => _wallet = val);
                          _updatePaymentSettings();
                        },
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.gold),
              ),
            ),
        ],
      ),
    );
  }
}
