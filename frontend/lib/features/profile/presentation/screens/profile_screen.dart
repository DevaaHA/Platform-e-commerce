import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'shipping_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'ai_fitting_settings_screen.dart';
import 'wallet_screen.dart';
import 'coupons_screen.dart';
import 'loyalty_points_screen.dart';
import 'support_screen.dart';
import 'orders_history_screen.dart';
import 'wishlist_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // متغيرات البيانات
  String _firstName = 'زائر';
  String _lastName = '';
  String _email = 'guest@souqjo.com';
  String _userRole = 'customer';

  bool _notificationsEnabled = true;
  String _phoneNumber = 'غير محدد';
  String _academicMajor = 'غير محدد';
  String _city = 'غير محدد';

  String _profileImagePath = '';
  File? _selectedImage;

  double _walletBalance = 0.0;
  int _availableCoupons = 0;
  int _userPoints = 0;

  String _currentLang = 'العربية';
  String _currentCurrency = 'د.أ (JOD)';
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _fetchFreshProfileData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name') ?? 'زائر';
      _lastName = prefs.getString('last_name') ?? '';
      _email = prefs.getString('user_email') ?? 'guest@souqjo.com';
      _userRole = prefs.getString('user_role') ?? 'customer';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _phoneNumber = prefs.getString('user_phone') ?? 'غير محدد';
      _academicMajor = prefs.getString('user_major') ?? 'غير محدد';
      _city = prefs.getString('user_city') ?? 'غير محدد';
      _profileImagePath = prefs.getString('user_profile_image') ?? '';
      _walletBalance = prefs.getDouble('wallet_balance') ?? 0.0;
      _userPoints = prefs.getInt('user_points') ?? 0;
      _availableCoupons = prefs.getInt('available_coupons') ?? 0;
      _currentLang = prefs.getString('app_language') ?? 'العربية';
      _currentCurrency = prefs.getString('app_currency') ?? 'د.أ (JOD)';
      _isDarkMode = prefs.getBool('app_dark_mode') ?? true;
    });
  }

  Future<void> _fetchFreshProfileData() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();

        setState(() {
          _firstName = data['first_name'] ?? _firstName;
          _lastName = data['last_name'] ?? _lastName;
          _phoneNumber = data['phone'] ?? _phoneNumber;
          _city = data['city'] ?? _city;
          _academicMajor = data['major'] ?? _academicMajor;
          _walletBalance =
              double.tryParse(data['wallet_balance'].toString()) ??
              _walletBalance;
          _userPoints = data['points'] ?? _userPoints;
          _availableCoupons = data['coupons_count'] ?? _availableCoupons;

          if (data['profile_image'] != null) {
            _profileImagePath = data['profile_image'];
          }
        });

        await prefs.setString('first_name', _firstName);
        await prefs.setString('user_phone', _phoneNumber);
        await prefs.setString('user_city', _city);
        await prefs.setString('user_major', _academicMajor);
        await prefs.setDouble('wallet_balance', _walletBalance);

        if (_profileImagePath.isNotEmpty) {
          await prefs.setString('user_profile_image', _profileImagePath);
        }
      }
    } catch (e) {
      debugPrint('لم يتمكن من جلب بيانات البروفايل الجديدة: $e');
    }
  }

  Future<void> _updateProfileFieldOnServer(
    String backendKey,
    String newValue,
    String localKey,
    Function(String) updateUI,
  ) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.patch(
        ApiConstants.profile,
        data: {backendKey: newValue},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        updateUI(newValue);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(localKey, newValue);

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم التحديث بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('فشل التحديث من السيرفر');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ حدث خطأ أثناء التحديث، حاول مجدداً'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
      });

      try {
        // سيتم تفعيل الكود الحقيقي عند توفر api_service.dart
        await Future.delayed(const Duration(seconds: 2));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_image', image.path);

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم اختيار الصورة! (بانتظار الربط مع السيرفر)'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ حدث خطأ أثناء اختيار الصورة'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showEditProfileDialog(
    String title,
    String initialValue,
    String backendKey,
    String localKey,
    Function(String) onSaved,
  ) {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'تعديل $title',
          style: const TextStyle(color: AppTheme.gold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'أدخل $title الجديد',
            labelStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
            onPressed: () {
              Navigator.pop(context);
              _updateProfileFieldOnServer(
                backendKey,
                controller.text,
                localKey,
                onSaved,
              );
            },
            child: const Text(
              'حفظ التعديل',
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

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (mounted) {
      setState(() => _notificationsEnabled = value);
    }
  }

  Future<void> _toggleThemeMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_dark_mode', value);
    if (mounted) {
      setState(() => _isDarkMode = value);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openSecuritySettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إعدادات الأمان قيد التطوير'),
        backgroundColor: AppTheme.gold,
      ),
    );
  }

  void _openLanguageAndCurrencySettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('اللغة: $_currentLang | العملة: $_currentCurrency'),
        backgroundColor: AppTheme.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String badgeText = 'عضو VIP ✨';
    if (_userRole == 'store_admin' || _userRole == 'merchant') {
      badgeText = 'تاجر 🏪';
    }
    if (_userRole == 'driver') {
      badgeText = 'كابتن توصيل 🛵';
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        automaticallyImplyLeading: false,
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(color: AppTheme.gold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: AppTheme.gold),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.gold.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _changeProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2D3E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.gold,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : (_profileImagePath.isNotEmpty
                                            ? Image.network(
                                                _profileImagePath,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    const Icon(
                                                      Icons.person,
                                                      size: 40,
                                                      color: AppTheme.gold,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                size: 40,
                                                color: AppTheme.gold,
                                              )),
                                ),
                              ),
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AppTheme.gold,
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 12,
                                    color: AppTheme.darkBg,
                                  ),
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$_firstName $_lastName'.trim(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.gold),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: const TextStyle(
                                        color: AppTheme.gold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phoneNumber,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showEditProfileDialog(
                            'رقم الهاتف',
                            _phoneNumber,
                            'phone',
                            'user_phone',
                            (val) => setState(() => _phoneNumber = val),
                          ),
                          child: _buildInfoRow(
                            Icons.phone_outlined,
                            'رقم الهاتف',
                            _phoneNumber,
                            isEditable: true,
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        GestureDetector(
                          onTap: () => _showEditProfileDialog(
                            'التخصص الأكاديمي',
                            _academicMajor,
                            'major',
                            'user_major',
                            (val) => setState(() => _academicMajor = val),
                          ),
                          child: _buildInfoRow(
                            Icons.school_outlined,
                            'التخصص الأكاديمي',
                            _academicMajor,
                            isEditable: true,
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        GestureDetector(
                          onTap: () => _showEditProfileDialog(
                            'المدينة',
                            _city,
                            'city',
                            'user_city',
                            (val) => setState(() => _city = val),
                          ),
                          child: _buildInfoRow(
                            Icons.location_on_outlined,
                            'المدينة',
                            _city,
                            isEditable: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildStatCard(
                        'رصيد المحفظة',
                        '${_walletBalance.toStringAsFixed(2)} د.أ',
                        Icons.account_balance_wallet_outlined,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletScreen(),
                            ),
                          );
                          _fetchFreshProfileData();
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'الكوبونات',
                        '$_availableCoupons متاح',
                        Icons.local_offer_outlined,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CouponsScreen(),
                            ),
                          );
                          _fetchFreshProfileData();
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'نقاط الولاء',
                        '$_userPoints نقطة',
                        Icons.stars_outlined,
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoyaltyPointsScreen(),
                            ),
                          );
                          _fetchFreshProfileData();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // قسم الطلبات
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'طلباتـي 📦',
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrdersHistoryScreen(),
                                ),
                              ),
                              child: const Text(
                                'عرض الكل',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildOrderShortcut(
                              Icons.payment,
                              'بانتظار الدفع',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrdersHistoryScreen(),
                                ),
                              ),
                            ),
                            _buildOrderShortcut(
                              Icons.inventory_2_outlined,
                              'قيد التجهيز',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrdersHistoryScreen(),
                                ),
                              ),
                            ),
                            _buildOrderShortcut(
                              Icons.local_shipping_outlined,
                              'جاري الشحن',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrdersHistoryScreen(),
                                ),
                              ),
                            ),
                            _buildOrderShortcut(
                              Icons.star_border,
                              'بانتظار التقييم',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrdersHistoryScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildMenuItem(
                    Icons.location_on_outlined,
                    'عناوين الشحن المحفوظة',
                    'إدارة عناوين التوصيل الدائمة',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShippingAddressesScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.payment_outlined,
                    'طرق الدفع والبطاقات',
                    'إدارة البطاقات المشفرة (Visa / MC)',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentMethodsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.checkroom,
                    'إعدادات غرفة القياس بالـ AI',
                    'تعديل الطول والوزن والمقاسات المفضلة',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiFittingSettingsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.favorite_outline,
                    'المنتجات المفضلة',
                    'قائمة الرغبات الحقيقية',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WishlistScreen(),
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        secondary: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.gold,
                        ),
                        title: const Text(
                          'إعدادات الإشعارات والعروض',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: _notificationsEnabled,
                        activeTrackColor: AppTheme.gold,
                        onChanged: _toggleNotifications,
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        secondary: const Icon(
                          Icons.brightness_6,
                          color: AppTheme.gold,
                        ),
                        title: const Text(
                          'وضع العرض (Dark / Light Mode)',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: _isDarkMode,
                        activeTrackColor: AppTheme.gold,
                        onChanged: _toggleThemeMode,
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    Icons.security_outlined,
                    'الأمان وكلمة المرور',
                    'تحديث كلمة المرور وحماية الحساب بـ JWT',
                    () => _openSecuritySettings(context),
                  ),
                  _buildMenuItem(
                    Icons.language,
                    'اللغة والعملة الافتراضية',
                    '$_currentLang | $_currentCurrency',
                    () => _openLanguageAndCurrencySettings(context),
                  ),
                  _buildMenuItem(
                    Icons.headset_mic_outlined,
                    'خدمة العملاء والدعم الفني',
                    'شات مباشر مع فريق الدعم',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    Icons.info_outline,
                    'عن متجر سوق جو',
                    'الإصدار 1.0.0 | منصة تسوق ذكية',
                    () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'سوق جو (SouqJo)',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'منصة تسوق إلكتروني ذكية مدعومة بالذكاء الاصطناعي - إربد، الأردن',
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      label: const Text(
                        'تسجيل الخروج من الحساب',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String subtitle, {
    bool isEditable = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.gold, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        if (isEditable)
          const Icon(Icons.edit_outlined, color: Colors.white24, size: 16),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.gold, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderShortcut(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.darkBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold.withAlpha(50)),
            ),
            child: Icon(icon, color: AppTheme.gold, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.gold),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white24,
            size: 14,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
