import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  int _currentPoints = 340;
  double _walletBalance = 0.00;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // تحميل البيانات الحقيقية من SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPoints = prefs.getInt('user_points') ?? 340;
      _walletBalance = prefs.getDouble('wallet_balance') ?? 15.50;
    });
  }

  // دالة تحويل النقاط إلى المحفظة وحفظها محلياً
  Future<void> _convertToWallet() async {
    if (_currentPoints < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ عذراً، الحد الأدنى للتحويل هو 100 نقطة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double convertedAmount =
        (_currentPoints / 100); // كل 100 نقطة = 1 دينار
    final double newWalletBalance = _walletBalance + convertedAmount;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet_balance', newWalletBalance);
    await prefs.setInt('user_points', 0); // تصفير النقاط

    setState(() {
      _walletBalance = newWalletBalance;
      _currentPoints = 0;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💰 تم تحويل النقاط بنجاح وإضافة ${convertedAmount.toStringAsFixed(2)} د.أ إلى المحفظة!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '⭐ نقاط الولاء والمكافآت',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars, color: AppTheme.gold, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'رصيدك الحالي من النقاط',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_currentPoints نقطة',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'كل 100 نقطة = 1.00 دينار أردني',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // عرض رصيد المحفظة الحالي للتأكيد
                  Text(
                    'رصيد المحفظة الحالي: ${_walletBalance.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _convertToWallet,
                      child: const Text(
                        'تحويل النقاط إلى المحفظة 💳',
                        style: TextStyle(
                          color: AppTheme.darkBg,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
