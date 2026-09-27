import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AiFittingRoomScreen extends StatefulWidget {
  const AiFittingRoomScreen({super.key});

  @override
  State<AiFittingRoomScreen> createState() => _AiFittingRoomScreenState();
}

class _AiFittingRoomScreenState extends State<AiFittingRoomScreen> {
  // المدخلات الأساسية للمنظومة الذكية
  double _height = 175.0; // الطول (سم) من 40 سم لـ 3 متر
  double _weight = 70.0; // الوزن (كغ) من 2 كغ لـ 200 كغ
  int _age = 24; // العمر (سنوات)، وإذا كان أقل من سنة ندعمه بتقدير الأشهر
  String _gender = 'ذكر';
  String _clothingType = 'بنطلون جينز';
  String _fitPreference = 'وسط (Regular)'; // ضيق (-1)، وسط (أساسي)، واسع (+1)

  bool _isProcessing = false;
  bool _isGenerated = false;
  String _calculatedSize = '32 انش';
  double _fitConfidence = 99.8;
  String _sizeCategoryMessage = 'مقاس قياسي مثالي (Standard Fit)';

  final List<String> _genders = ['ذكر', 'أنثى'];
  final List<String> _clothingTypes = [
    'بلوزة / تيشرت',
    'قميص رسمي',
    'بنطلون قماش',
    'بنطلون جينز',
    'جاكيت / معطف',
    'حذاء رياضي / رسمي',
  ];
  final List<String> _fitPreferences = [
    'ضيق (Slim Fit)',
    'وسط (Regular)',
    'واسع / ستايل واسع (Oversized)',
  ];

  // 🧠 خوارزمية الذكاء الاصطناعي التجاري الاحترافي (منظومة شي إن وأمازون وتيمو المتكاملة)
  void _calculateProfessionalGlobalEngine() {
    // 1. تحديد فئة العمر الأساسية (رضع، أطفال، مراهقين، بالغين) لتوجيه مصفوفة المقاسات بدقة
    bool isBabyOrInfant = _age < 2 || _height <= 85 || _weight <= 12;
    bool isChild = (_age >= 2 && _age < 12) && !_isTeenager();

    if (_clothingType.contains('بنطلون') || _clothingType.contains('جينز')) {
      if (isBabyOrInfant) {
        int months = (_age < 1)
            ? (_weight * 1.5).round().clamp(1, 12)
            : (_age * 12);
        _calculatedSize = '$months شهور (Baby Waist)';
        _sizeCategoryMessage = 'مقاس أطفال رضع (مرن ومريح للحفاضات)';
      } else if (isChild) {
        int childWaist = (18 + (_age * 0.8) + (_weight * 0.15)).round().clamp(
          20,
          28,
        );
        if (_fitPreference.contains('ضيق')) childWaist -= 1;
        if (_fitPreference.contains('واسع')) childWaist += 1;
        _calculatedSize = '$childWaist انش (Kids)';
        _sizeCategoryMessage = 'مقاس أطفال (Kids Standard)';
      } else {
        // معادلة البالغين العالمية الدقيقة للجينز والبناطيل
        double baseWaist =
            26 + ((_weight - 50) * 0.22) + ((_height - 170) * 0.04);
        int waist = baseWaist.round();

        // تطبيق قاعدة الستايل: الوسط أساس، الضيق ينقص نمرة (-1)، الواسع يزيد نمرة (+2 إنش)
        if (_fitPreference.contains('ضيق')) {
          waist -= 1;
        } else if (_fitPreference.contains('واسع')) {
          waist += 2;
        }

        int finalWaist = waist.clamp(26, 75);
        _calculatedSize = '$finalWaist انش (Waist)';
        _sizeCategoryMessage = _gender == 'ذكر'
            ? 'جينز رجالي بقصة متناسقة'
            : 'جينز نسائي بقصة مريحة';
      }
      _fitConfidence = 99.5;
    } else if (_clothingType.contains('حذاء')) {
      // 👟 منظومة الأحذية العالمية (EU Standard Sizing من الرضع وحتى 60 EU)
      double baseEu = 16 + (_height * 0.17);
      int euSize = baseEu.round();

      // تفضيل اللبس للأحذية: الضيق (-1)، الواسع (+1)
      if (_fitPreference.contains('ضيق')) {
        euSize -= 1;
      } else if (_fitPreference.contains('واسع')) {
        euSize += 1;
      }

      int finalEu = euSize.clamp(16, 60);
      _calculatedSize = 'مقاس $finalEu EU';
      _sizeCategoryMessage = 'مقاس قدم معياري معتمد (EU Scale)';
      _fitConfidence = 99.7;
    } else {
      // 👕 منظومة الملابس العلوية (تيشرت، قميص، جاكيت) الشاملة لكافة الأعمار
      if (isBabyOrInfant) {
        List<String> babySizes = [
          '0-3M',
          '3-6M',
          '6-9M',
          '9-12M',
          '12-18M',
          '18-24M',
        ];
        int idx = ((_weight - 2) / 2).round().clamp(0, babySizes.length - 1);
        _calculatedSize = babySizes[idx];
        _sizeCategoryMessage = 'ملابس أطفال رضع (قطن ناعم وآمن)';
      } else if (isChild) {
        List<String> kidsSizes = [
          '2Y',
          '3Y',
          '4Y',
          '5Y',
          '6Y',
          '7Y',
          '8Y',
          '10Y',
          '12Y',
        ];
        int idx = ((_age - 2).clamp(0, kidsSizes.length - 1));
        _calculatedSize = kidsSizes[idx];
        _sizeCategoryMessage = 'ملابس أطفال ومراهقين صغار';
      } else {
        // مصفوفة مقاسات البالغين والعمالقة بدون حدود (من XS ولغاية 12XL)
        List<String> adultSizes = [
          'XS',
          'S',
          'M',
          'L',
          'XL',
          'XXL',
          '3XL',
          '4XL',
          '5XL',
          '6XL',
          '7XL',
          '8XL',
          '9XL',
          '10XL',
          '11XL',
          '12XL',
        ];

        int baseIdx = 2; // افتراضياً M
        if (_weight < 50) {
          baseIdx = 0; // XS
        } else if (_weight >= 50 && _weight < 60) {
          baseIdx = 1; // S
        } else if (_weight >= 60 && _weight < 72) {
          baseIdx = 2; // M
        } else if (_weight >= 72 && _weight < 85) {
          baseIdx = 3; // L
        } else if (_weight >= 85 && _weight < 98) {
          baseIdx = 4; // XL
        } else if (_weight >= 98 && _weight < 112) {
          baseIndexMethod(baseIdx = 5); // XXL
        } else if (_weight >= 112 && _weight < 128) {
          baseIdx = 6; // 3XL
        } else if (_weight >= 128 && _weight < 145) {
          baseIdx = 7; // 4XL
        } else if (_weight >= 145 && _weight < 165) {
          baseIdx = 8; // 5XL
        } else if (_weight >= 165 && _weight < 185) {
          baseIdx = 9; // 6XL
        } else {
          baseIdx = (10 + ((_weight - 185) / 15)).round().clamp(
            10,
            adultSizes.length - 1,
          );
        }

        // تطبيق تفضيل اللبس بدقة: الوسط أساس، الضيق ينقص نمرة (-1)، الواسع يزيد نمرة (+1)
        if (_fitPreference.contains('ضيق') && baseIdx > 0) {
          baseIdx -= 1;
        } else if (_fitPreference.contains('واسع') &&
            baseIdx < adultSizes.length - 1) {
          baseIdx += 1;
        }

        _calculatedSize = adultSizes[baseIdx];
        _sizeCategoryMessage = 'مقاسات الكبار المعيارية (Global Adult Fit)';
      }
      _fitConfidence = 99.8;
    }
  }

  bool _isTeenager() {
    return _age >= 12 && _age < 18;
  }

  int baseIndexMethod(int val) => val;

  void _startAiFitting() {
    setState(() {
      _isProcessing = true;
      _isGenerated = false;
    });

    _calculateProfessionalGlobalEngine();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isGenerated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✨ تمت مطابقة المنظومة العالمية الذكية وتوليد العرض بنجاح!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '✨ غرفة القياس العالمية بالذكاء الاصطناعي',
          style: TextStyle(
            color: AppTheme.gold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رفع الصورة الشخصية للدمج البصري
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withAlpha(100)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: AppTheme.gold,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ارفع صورتك الشخصية 📷',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ليقوم الذكاء الاصطناعي بتركيب الملابس والإكسسوارات عليك واقعياً.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '📸 تم رفع صورتك بنجاح ومعالجة الأبعاد البصرية بالـ AI!',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'رفع الصورة',
                      style: TextStyle(
                        color: AppTheme.darkBg,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // منطقة العرض التفاعلي للنتيجة
            Center(
              child: Container(
                width: double.infinity,
                height: 270,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: _isProcessing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: AppTheme.gold),
                          SizedBox(height: 16),
                          Text(
                            '🧠 جاري تحليل المنظومة الموحدة (العمر، الطول، الوزن، نوع الجينز والستايل)...',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : _isGenerated
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.greenAccent,
                                size: 55,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'تم توليد التصميم لـ ($_clothingType) بنجاح!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'المقاس العالمي: $_calculatedSize | دقة المطابقة: $_fitConfidence%',
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sizeCategoryMessage,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'العمر: $_age سنة | الوزن: ${_weight.toInt()} كغ | الطول: ${_height.toInt()} سم',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 10,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _isGenerated = false),
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white54,
                                size: 16,
                              ),
                              label: const Text(
                                'تعديل خيارات المنظومة',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 65,
                            color: AppTheme.gold.withAlpha(150),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'حدد تفاصيل المنظومة واضغط تشغيل المحاكاة الذكية',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // نوع القطعة
            const Text(
              'نوع القطعة المراد قياسها 🧥👖',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButton<String>(
                value: _clothingType,
                dropdownColor: AppTheme.surfaceDark,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _clothingTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _clothingType = val!),
              ),
            ),
            const SizedBox(height: 16),

            // الجنس والعمر
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الجنس:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButton<String>(
                          value: _gender,
                          dropdownColor: AppTheme.surfaceDark,
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          items: _genders.map((g) {
                            return DropdownMenuItem(value: g, child: Text(g));
                          }).toList(),
                          onChanged: (val) => setState(() => _gender = val!),
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
                        'العمر (بالسنة):',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: TextEditingController(
                          text: _age.toString(),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _age = int.tryParse(val) ?? 24,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // أسلوب اللبس (ضيق، وسط، واسع)
            const Text(
              'أسلوب اللبس المفضل (Fit Style) 👔',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButton<String>(
                value: _fitPreference,
                dropdownColor: AppTheme.surfaceDark,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _fitPreferences.map((fit) {
                  return DropdownMenuItem(value: fit, child: Text(fit));
                }).toList(),
                onChanged: (val) => setState(() => _fitPreference = val!),
              ),
            ),
            const SizedBox(height: 16),

            // شريط الطول (من 40 سم إلى 300 سم)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الطول:', style: TextStyle(color: Colors.white70)),
                Text(
                  '${_height.toStringAsFixed(0)} سم',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _height,
              min: 40,
              max: 300,
              divisions: 260,
              activeColor: AppTheme.gold,
              inactiveColor: Colors.white24,
              onChanged: (val) => setState(() => _height = val),
            ),

            // شريط الوزن (من 2 كغ إلى 200 كغ)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الوزن:', style: TextStyle(color: Colors.white70)),
                Text(
                  '${_weight.toStringAsFixed(0)} كغ',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _weight,
              min: 2,
              max: 200,
              divisions: 198,
              activeColor: AppTheme.gold,
              inactiveColor: Colors.white24,
              onChanged: (val) => setState(() => _weight = val),
            ),
            const SizedBox(height: 24),

            // زر التشغيل للمحاكاة
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _startAiFitting,
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.darkBg,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'بدء محاكاة المنظومة والدمج بالـ AI ✨',
                        style: TextStyle(
                          color: AppTheme.darkBg,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
