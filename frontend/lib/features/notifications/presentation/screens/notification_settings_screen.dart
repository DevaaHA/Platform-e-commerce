import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _marketingEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final response = await _apiService.get(ApiConstants.notificationSettings);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _pushEnabled = data['push_enabled'] ?? true;
          _emailEnabled = data['email_enabled'] ?? true;
          _smsEnabled = data['sms_enabled'] ?? false;
          _marketingEnabled = data['marketing_enabled'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    try {
      await _apiService.patch(
        ApiConstants.notificationSettings,
        data: {
          'push_enabled': _pushEnabled,
          'email_enabled': _emailEnabled,
          'sms_enabled': _smsEnabled,
          'marketing_enabled': _marketingEnabled,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الإشعارات بنجاح ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حفظ الإعدادات')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إعدادات الإشعارات ⚙️',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text(
                    'الإشعارات الفورية (Push Notifications)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'تلقي تنبيهات حالة الطلب والشحن مباشرة',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _pushEnabled,
                  activeThumbColor: AppTheme.gold, // تم التحديث لتجنب التحذير
                  onChanged: (val) {
                    setState(() => _pushEnabled = val);
                    _updateSettings();
                  },
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  title: const Text(
                    'إشعارات البريد الإلكتروني (Email)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'تلقي الفواتير وملخصات الطلبات عبر الإيميل',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _emailEnabled,
                  activeThumbColor: AppTheme.gold, // تم التحديث لتجنب التحذير
                  onChanged: (val) {
                    setState(() => _emailEnabled = val);
                    _updateSettings();
                  },
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  title: const Text(
                    'الرسائل النصية (SMS)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'تلقي رموز التحقق OTP وتأكيدات الدفع',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _smsEnabled,
                  activeThumbColor: AppTheme.gold, // تم التحديث لتجنب التحذير
                  onChanged: (val) {
                    setState(() => _smsEnabled = val);
                    _updateSettings();
                  },
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  title: const Text(
                    'العروض والحملات التسويقية',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'تلقي الكوبونات وأحدث خصومات المتاجر',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _marketingEnabled,
                  activeThumbColor: AppTheme.gold, // تم التحديث لتجنب التحذير
                  onChanged: (val) {
                    setState(() => _marketingEnabled = val);
                    _updateSettings();
                  },
                ),
              ],
            ),
    );
  }
}
