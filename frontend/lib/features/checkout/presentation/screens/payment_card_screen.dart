import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class PaymentCardScreen extends StatefulWidget {
  final String orderId;
  final double amount;

  const PaymentCardScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<PaymentCardScreen> createState() => _PaymentCardScreenState();
}

class _PaymentCardScreenState extends State<PaymentCardScreen> {
  final ApiService _apiService = ApiService();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _payWithCard() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.post(
        ApiConstants.processPayment,
        data: {
          'order_id': widget.orderId,
          'amount': widget.amount,
          'card_number': _cardNumberController.text.trim(),
          'expiry': _expiryController.text.trim(),
          'cvv': _cvvController.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الدفع بنجاح عبر البطاقة الائتمانية الآمنة 🔒✅'),
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل عملية الدفع بالبطاقة. تحقق من البيانات.'),
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
        title: const Text(
          'الدفع الإلكتروني الآمن 🔒',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Row(
              children: const [
                Icon(Icons.lock, color: Colors.greenAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'اتصال مشفر وآمن بالكامل (SSL 256-bit)',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'اسم حامل البطاقة',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: 'Full Name',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'رقم البطاقة الائتمانية',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: '0000 0000 0000 0000',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تاريخ الانتهاء',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _expiryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          hintText: 'MM/YY',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رمز الأمان CVV',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          hintText: '123',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                onPressed: _isLoading ? null : _payWithCard,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBg,
                        ),
                      )
                    : Text(
                        'ادفع ${widget.amount} د.أ بأمان',
                        style: const TextStyle(
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
