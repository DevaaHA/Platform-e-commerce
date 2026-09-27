import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AdminHomepageBuilderScreen extends StatefulWidget {
  const AdminHomepageBuilderScreen({super.key});

  @override
  State<AdminHomepageBuilderScreen> createState() =>
      _AdminHomepageBuilderScreenState();
}

class _AdminHomepageBuilderScreenState
    extends State<AdminHomepageBuilderScreen> {
  final ApiService _apiService = ApiService();

  // تم إضافة final هنا لتلبية معايير الجودة والتحسين البرمجي (Lint Rules)
  final List<Map<String, dynamic>> _sections = [
    {'name': 'الباستر الرئيسي (Hero Banner)', 'order': 1, 'enabled': true},
    {'name': 'التصنيفات السريعة (Categories)', 'order': 2, 'enabled': true},
    {
      'name': 'المنتجات الأكثر مبيعاً (Featured Products)',
      'order': 3,
      'enabled': true,
    },
    {'name': 'العروض والخصومات (Offers)', 'order': 4, 'enabled': true},
    {'name': 'المتاجر المميزة (Top Stores)', 'order': 5, 'enabled': true},
  ];

  Future<void> _updateHomepageOrder() async {
    try {
      // إرسال الترتيب وتحديثات الأقسام الحقيقية إلى الباك إيند عبر الـ API
      await _apiService.patch(
        ApiConstants.homepageContent,
        data: {'sections': _sections},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ وتحديث ترتيب الصفحة الرئيسية في قاعدة البيانات بنجاح 🚀',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الاتصال بالسيرفر لحفظ الترتيب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'بناء وإدارة الصفحة الرئيسية (CMS) 📱',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'قم بترتيب أو تفعيل وإلغاء تفعيل أقسام الواجهة الرئيسية لتظهر للعملاء بشكل ديناميكي فوري:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.drag_handle,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              section['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: section['enabled'],
                          activeThumbColor: AppTheme.gold,
                          onChanged: (val) {
                            setState(() {
                              _sections[index]['enabled'] = val;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.darkBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _updateHomepageOrder,
                child: const Text(
                  'حفظ الترتيب والتحديث الفوري',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
