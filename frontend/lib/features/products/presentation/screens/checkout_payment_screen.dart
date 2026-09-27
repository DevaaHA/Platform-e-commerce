import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;

  const CheckoutPaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final ApiService _apiService = ApiService();
  String _selectedMethod = 'COD'; // COD: Cash on Delivery, Card: Credit Card
  bool _isLoading = false;

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        ApiConstants.paymentCreate,
        data: {
          'order_id': widget.orderId,
          'payment_method': _selectedMethod,
          'amount': widget.totalAmount,
          if (_selectedMethod == 'Card') ...{
            'card_number': _cardNumberController.text.trim(),
            'expiry': _expiryController.text.trim(),
            'cvv': _cvvController.text.trim(),
            'card_holder': _cardHolderController.text.trim(),
          },
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت عملية الدفع بنجاح 🚀')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل معالجة الدفع. يرجى المحاولة مرة أخرى.'),
        ),
      );
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
          'إتمام الدفع (Checkout Payment)',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المبلغ المطلوب: ${widget.totalAmount} د.أ',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'اختر طريقة الدفع:',
                style: TextStyle(color: AppTheme.white, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // تصميم بطاقات الاختيار الحديثة (بدون استخدام Radio لتجنب التحذيرات نهائياً)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'COD'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedMethod == 'COD'
                              ? AppTheme.gold.withValues(alpha: 0.15)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedMethod == 'COD'
                                ? AppTheme.gold
                                : Colors.white10,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              color: _selectedMethod == 'COD'
                                  ? AppTheme.gold
                                  : AppTheme.textMuted,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'عند الاستلام',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'Card'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedMethod == 'Card'
                              ? AppTheme.gold.withValues(alpha: 0.15)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedMethod == 'Card'
                                ? AppTheme.gold
                                : Colors.white10,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.credit_card,
                              color: _selectedMethod == 'Card'
                                  ? AppTheme.gold
                                  : AppTheme.textMuted,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'بطاقة ائتمان',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedMethod == 'Card') ...[
                TextField(
                  controller: _cardHolderController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم حامل البطاقة',
                    labelStyle: TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'رقم البطاقة',
                    labelStyle: TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'MM/YY',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _processPayment,
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
                          'إتمام الدفع وتأكيد الطلب',
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
      ),
    );
  }
}
