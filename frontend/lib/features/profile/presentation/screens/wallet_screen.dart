import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 18.90;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  // 📥 استرجاع رصيد المحفظة وسجل المعاملات بشكل دائم من SharedPreferences
  Future<void> _loadWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = prefs.getDouble('wallet_balance') ?? 18.90;

      // معاملات مالية افتراضية واقعية للمنصة
      _transactions = [
        {
          'type': 'credit',
          'title': 'استرداد نقدي (كاش باك)',
          'date': '2026-08-25',
          'amount': '+5.00 د.أ',
          'isPositive': true,
        },
        {
          'type': 'debit',
          'title': 'خصم قيمة الطلب #SOQ-8843',
          'date': '2026-08-12',
          'amount': '-25.50 د.أ',
          'isPositive': false,
        },
        {
          'type': 'credit',
          'title': 'شحن رصيد المحفظة السريع',
          'date': '2026-08-01',
          'amount': '+40.00 د.أ',
          'isPositive': true,
        },
      ];
    });
  }

  // 💳 شحن المحفظة ومحاكاة بوابة الدفع الإلكترونية
  Future<void> _addFunds(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance += amount;
      _transactions.insert(0, {
        'type': 'credit',
        'title': 'شحن رصيد إلكتروني (بطاقة بنكية)',
        'date': DateTime.now().toString().substring(0, 10),
        'amount': '+$amount.00 د.أ',
        'isPositive': true,
      });
    });

    await prefs.setDouble('wallet_balance', _balance);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ تمت عملية الشحن بنجاح! وأضيف مبلغ $amount.00 د.أ إلى رصيدك',
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
          '💰 محفظة سوق جو المالية',
          style: TextStyle(
            color: AppTheme.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // بطاقة الرصيد الفاخرة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withAlpha(20),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'الرصيد المتاح الحالي للدفع',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_balance.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _addFunds(10.0),
                    icon: const Icon(
                      Icons.add_card,
                      color: AppTheme.darkBg,
                      size: 18,
                    ),
                    label: const Text(
                      'شحن سريع (+10 د.أ)',
                      style: TextStyle(
                        color: AppTheme.darkBg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'سجل المعاملات المالية 📄',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // قائمة سجل المعاملات الحقيقية
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  bool isPos = tx['isPositive'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isPos ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isPos ? Colors.green : Colors.redAccent,
                      ),
                      title: Text(
                        tx['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        tx['date'],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Text(
                        tx['amount'],
                        style: TextStyle(
                          color: isPos ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
