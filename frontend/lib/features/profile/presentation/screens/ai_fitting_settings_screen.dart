import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class AiFittingSettingsScreen extends StatefulWidget {
  const AiFittingSettingsScreen({super.key});

  @override
  State<AiFittingSettingsScreen> createState() =>
      _AiFittingSettingsScreenState();
}

class _AiFittingSettingsScreenState extends State<AiFittingSettingsScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedStyle = 'وسط (Regular)';

  final List<String> _styleOptions = [
    'ضيق (Slim)',
    'وسط (Regular)',
    'واسع (Oversized)',
  ];

  @override
  void initState() {
    super.initState();
    _loadFittingData();
  }

  // 📥 استرجاع المقاسات المحفوظة دائمياً عند فتح الشاشة
  Future<void> _loadFittingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _heightController.text = prefs.getString('ai_height') ?? '184';
      _weightController.text = prefs.getString('ai_weight') ?? '76';
      _selectedStyle = prefs.getString('ai_style') ?? 'وسط (Regular)';
    });
  }

  // 💾 حفظ مقاسات الذكاء الاصطناعي بشكل دائم في الذاكرة المحلية
  Future<void> _saveAiFittingSettings() async {
    if (_heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_height', _heightController.text.trim());
      await prefs.setString('ai_weight', _weightController.text.trim());
      await prefs.setString('ai_style', _selectedStyle);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✨ تم حفظ وتحديث مقاسات الذكاء الاصطناعي بنجاح وتطبيقها في غرفة القياس!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى التأكد من إدخال الطول والوزن بشكل صحيح'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '✨ إعدادات غرفة القياس بالـ AI',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعديل بيانات المقاسات الافتراضية الخاصة بك:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gold.withAlpha(100)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الطول (سم)',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الوزن (كغ)',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تفضيل الستايل:',
                        style: TextStyle(color: Colors.white54),
                      ),
                      DropdownButton<String>(
                        value: _selectedStyle,
                        dropdownColor: AppTheme.surfaceDark,
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                        items: _styleOptions.map((String style) {
                          return DropdownMenuItem<String>(
                            value: style,
                            child: Text(style),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStyle = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveAiFittingSettings,
                child: const Text(
                  'حفظ ومزامنة المقاسات الذكية 🚀',
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
    );
  }
}
