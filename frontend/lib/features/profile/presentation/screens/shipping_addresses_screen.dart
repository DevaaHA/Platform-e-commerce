import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class ShippingAddressesScreen extends StatefulWidget {
  const ShippingAddressesScreen({super.key});

  @override
  State<ShippingAddressesScreen> createState() =>
      _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState extends State<ShippingAddressesScreen> {
  List<Map<String, String>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // 📥 استرجاع العناوين المحفوظة دائمياً من SharedPreferences
  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_shipping_addresses');

    if (savedData != null) {
      final List decodedList = jsonDecode(savedData);
      setState(() {
        _addresses = decodedList
            .map((item) => Map<String, String>.from(item))
            .toList();
      });
    } else {
      // العنوان الافتراضي الأول في حال لم تكن هناك عناوين مخزنة
      _addresses = [
        {
          'title': 'المنزل (العنوان الرئيسي)',
          'details':
              'إربد - شارع الجامعة - مقابل البوابة الرئيسية - عمارة رقم 12',
          'phone': '+962 7 9000 0000',
          'isDefault': 'true',
        },
      ];
      _saveAddresses();
    }
  }

  // 💾 حفظ العناوين بصيغة JSON بشكل دائم
  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_shipping_addresses', jsonEncode(_addresses));
  }

  void _showAddAddressDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '📍 إضافة عنوان شحن جديد',
          style: TextStyle(color: AppTheme.gold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'تسمية العنوان (مثل: العمل، بيت الأهل)',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'التفاصيل (المدينة، الشارع، رقم العمارة)',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف للتواصل',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                textDirection: TextDirection.ltr,
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
              if (titleController.text.isNotEmpty &&
                  detailsController.text.isNotEmpty) {
                setState(() {
                  _addresses.add({
                    'title': titleController.text,
                    'details': detailsController.text,
                    'phone': phoneController.text.isNotEmpty
                        ? phoneController.text
                        : '+962 7 9000 0000',
                    'isDefault': 'false',
                  });
                });

                // الحفظ الفوري والدائم في الذاكرة المحلية
                await _saveAddresses();

                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context);

                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم حفظ العنوان في النظام بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'حفظ العنوان',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '📍 عناوين الشحن المحفوظة',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._addresses.map(
            (addr) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: addr['isDefault'] == 'true'
                      ? AppTheme.gold
                      : Colors.white10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        addr['title']!,
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (addr['isDefault'] == 'true')
                        const Chip(
                          label: Text(
                            'افتراضي',
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    addr['details']!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'هاتف: ${addr['phone']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ),
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
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add, color: AppTheme.gold),
            label: const Text(
              'إضافة عنوان جديد',
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
