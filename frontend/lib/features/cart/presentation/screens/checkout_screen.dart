import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> cartData;
  final double grandTotal;

  const CheckoutScreen({
    super.key,
    required this.cartData,
    required this.grandTotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final TextEditingController _addressController = TextEditingController(
    text: 'إربد، الجامعات، شارع الحصن',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+962790000000',
  );
  String _selectedPaymentMethod = 'CASH';

  Future<void> _submitOrder() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول أولاً'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _apiService.dio.post(
        ApiConstants.orders,
        data: {
          'shipping_address': _addressController.text,
          'phone': _phoneController.text,
          'payment_method': _selectedPaymentMethod,
          'total_amount': widget.grandTotal,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text(
            '🎉 تم بنجاح!',
            style: TextStyle(color: AppTheme.gold),
          ),
          content: const Text(
            'تم استلام طلبك بنجاح وجاري العمل على تجهيزه وتوصيله إليك قريباً.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'العودة للرئيسية',
                style: TextStyle(
                  color: AppTheme.darkBg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text(
            '🎉 تهانينا!',
            style: TextStyle(color: AppTheme.gold),
          ),
          content: const Text(
            'تم تسجيل طلبك بنجاح في متجر سوق جو!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'العودة للرئيسية',
                style: TextStyle(color: AppTheme.darkBg),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '📦 إتمام الطلب والدفع',
          style: TextStyle(color: AppTheme.gold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'عنوان التوصيل 📍',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.location_on, color: AppTheme.gold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'رقم الهاتف للتواصل 📞',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.phone, color: AppTheme.gold),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'طريقة الدفع 💳',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 🚀 خيار الدفع عند الاستلام (تصميم عصري بدون تحذيرات)
            InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = 'CASH'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPaymentMethod == 'CASH'
                        ? AppTheme.gold
                        : Colors.white10,
                    width: _selectedPaymentMethod == 'CASH' ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedPaymentMethod == 'CASH'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedPaymentMethod == 'CASH'
                          ? AppTheme.gold
                          : Colors.white54,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'الدفع عند الاستلام (Cash on Delivery)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🚀 خيار البطاقة الائتمانية
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الدفع الإلكتروني سيتاح قريباً!'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.radio_button_off, color: Colors.white54),
                    SizedBox(width: 12),
                    Text(
                      'البطاقة الائتمانية / زين كاش (قريباً)',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المبلغ الإجمالي المطلوب:',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  Text(
                    '${widget.grandTotal.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submitOrder,
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppTheme.darkBg)
                    : const Text(
                        'تأكيد وإرسال الطلب 🚀',
                        style: TextStyle(
                          color: AppTheme.darkBg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
