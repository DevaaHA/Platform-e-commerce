import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import 'payment_card_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;

  const PaymentCheckoutScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final ApiService _apiService = ApiService();
  String _selectedMethod = 'cod';
  bool _isLoading = false;

  Future<void> _processCheckout() async {
    if (_selectedMethod == 'card') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentCardScreen(
            orderId: widget.orderId,
            amount: widget.totalAmount,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.post(
        ApiConstants.createPayment,
        data: {
          'order_id': widget.orderId,
          'payment_method': _selectedMethod,
          'amount': widget.totalAmount,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد الدفع وإتمام الطلب بنجاح 🛍️')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل معالجة عملية الدفع. حاول مرة أخرى.')),
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
          'اختيار طريقة الدفع 💳',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المبلغ الإجمالي: ${widget.totalAmount} د.أ',
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اختر وسيلة الدفع المناسبة:',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 12),
            // استخدام RadioGroup الحديث المعتمد في إصدارات فلاتر الحديثة لإدارة الحالة مركزياً وتجنب التنبيهات
            RadioGroup<String>(
              groupValue: _selectedMethod,
              onChanged: (String? val) {
                if (val != null) {
                  setState(() => _selectedMethod = val);
                }
              },
              child: Column(
                children: [
                  _buildPaymentOption(
                    'cod',
                    'الدفع عند الاستلام (Cash On Delivery)',
                    Icons.money,
                  ),
                  _buildPaymentOption(
                    'card',
                    'البطاقة الائتمانية / الإلكترونية (Credit Card)',
                    Icons.credit_card,
                  ),
                  _buildPaymentOption(
                    'wallet',
                    'المحفظة الإلكترونية (SouqJo Wallet)',
                    Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),
            const Spacer(),
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
                onPressed: _isLoading ? null : _processCheckout,
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
                        'متابعة الدفع وتأكيد الطلب',
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

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedMethod == value ? AppTheme.gold : Colors.white10,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedMethod = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.gold, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              // استخدام Radio بدون الخصائص القديمة ليتوافق تماماً مع RadioGroup الجديد
              Radio<String>(value: value, activeColor: AppTheme.gold),
            ],
          ),
        ),
      ),
    );
  }
}
