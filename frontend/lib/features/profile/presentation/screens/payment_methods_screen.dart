import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // 📥 استرجاع البطاقات وطرق الدفع المخزنة بشكل دائم
  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_payment_methods');

    if (savedData != null) {
      final List decodedList = jsonDecode(savedData);
      setState(() {
        _paymentMethods = decodedList.map((item) {
          return {
            'title': item['title'],
            'subtitle': item['subtitle'],
            'icon': item['isCard'] ? Icons.credit_card : Icons.money,
            'isDefault': item['isDefault'],
            'isCard': item['isCard'],
          };
        }).toList();
      });
    } else {
      // القيم الافتراضية الأولى
      _paymentMethods = [
        {
          'title': 'الدفع النقدي عند الاستلام',
          'subtitle': 'الدفع المباشر عند استلام الطلب',
          'icon': Icons.money,
          'isDefault': true,
          'isCard': false,
        },
        {
          'title': 'بطاقة الائتمان (Visa / MasterCard)',
          'subtitle': 'منتهية بـ **** 4092',
          'icon': Icons.credit_card,
          'isDefault': false,
          'isCard': true,
        },
      ];
      _saveCards();
    }
  }

  // 💾 حفظ البطاقات وطرق الدفع دائمياً بصيغة JSON
  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> temp = _paymentMethods.map((e) {
      return {
        'title': e['title'],
        'subtitle': e['subtitle'],
        'isDefault': e['isDefault'],
        'isCard': e['isCard'],
      };
    }).toList();
    await prefs.setString('saved_payment_methods', jsonEncode(temp));
  }

  void _showAddCardDialog() {
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController cardHolderController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '💳 إضافة بطاقة ائتمان جديدة',
          style: TextStyle(color: AppTheme.gold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                maxLength: 16,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'رقم البطاقة (16 رقم)',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cardHolderController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'اسم حامل البطاقة',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: expiryController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'تاريخ الانتهاء (MM/YY)',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
            onPressed: () async {
              if (cardNumberController.text.length >= 4) {
                String lastDigits = cardNumberController.text.substring(
                  cardNumberController.text.length - 4,
                );
                setState(() {
                  _paymentMethods.add({
                    'title': 'بطاقة ائتمان بنكية',
                    'subtitle': 'منتهية بـ **** $lastDigits',
                    'icon': Icons.credit_card,
                    'isDefault': false,
                    'isCard': true,
                  });
                });

                // الحفظ الفوري الدائم
                await _saveCards();

                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);

                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تمت إضافة وحفظ البطاقة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ يرجى إدخال رقم بطاقة صحيح'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              'حفظ البطاقة',
              style: TextStyle(
                color: AppTheme.darkBg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تحديث وحفظ طريقة الدفع الافتراضية دائماً
  Future<void> _setDefaultMethod(int index) async {
    setState(() {
      for (int i = 0; i < _paymentMethods.length; i++) {
        _paymentMethods[i]['isDefault'] = (i == index);
      }
    });

    await _saveCards();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 تم تحديث وحفظ طريقة الدفع الافتراضية'),
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
          '💳 طرق الدفع والبطاقات',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._paymentMethods.asMap().entries.map((entry) {
            int index = entry.key;
            Map method = entry.value;
            bool isDef = method['isDefault'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDef ? AppTheme.gold : Colors.white10,
                ),
              ),
              child: ListTile(
                leading: Icon(method['icon'], color: AppTheme.gold, size: 30),
                title: Text(
                  method['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  method['subtitle'],
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: isDef
                    ? const Chip(
                        label: Text(
                          'الافتراضية',
                          style: TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Colors.green,
                      )
                    : TextButton(
                        onPressed: () => _setDefaultMethod(index),
                        child: const Text(
                          'تعيين كافتراضي',
                          style: TextStyle(color: AppTheme.gold, fontSize: 12),
                        ),
                      ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceDark,
              side: const BorderSide(color: AppTheme.gold),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add_card, color: AppTheme.gold),
            label: const Text(
              'إضافة بطاقة ائتمان جديدة',
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
