import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class CouponBox extends StatefulWidget {
  final VoidCallback onCouponApplied;

  const CouponBox({super.key, required this.onCouponApplied});

  @override
  State<CouponBox> createState() => _CouponBoxState();
}

class _CouponBoxState extends State<CouponBox> {
  final _couponController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _apiService.post(
        ApiConstants.applyCoupon,
        data: {'code': code},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _message = 'تم تطبيق الكوبون بنجاح 🎉';
        });
        widget.onCouponApplied();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _message = 'كود الخصم غير صالح أو لا يستوفي الشروط';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'أدخل كود الخصم (مثال: SUMMER20)',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.darkBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _isLoading ? null : _applyCoupon,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBg,
                        ),
                      )
                    : const Text(
                        'تطبيق',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(
                color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
