import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import 'register_screen.dart';
import '../../../home/presentation/screens/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        'الرجاء إدخال البريد الإلكتروني وكلمة المرور',
        Colors.orangeAccent,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // 🔍 استخدام debugPrint بدلاً من print لكود نظيف واحترافي
        debugPrint("🔍 FULL LOGIN RESPONSE: $responseData");

        // التقاط التوكن من رد السيرفر (مفتاح الجلسة الآمن)
        final String? token =
            responseData['access'] ??
            responseData['token'] ??
            responseData['key'];

        // 🚀 التقاط دور المستخدم
        final String userRole =
            responseData['role'] ??
            responseData['user_role'] ??
            (responseData['user'] != null
                ? responseData['user']['role']
                : 'customer');

        debugPrint("🎯 DETECTED USER ROLE: $userRole");

        if (token != null && token.isNotEmpty) {
          await ApiService.setAuthToken(token); // حفظ التوكن في خدمة الـ API

          // 🚀 فتح الذاكرة وحفظ كاااامل تفاصيل المستخدم
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('auth_token', token); // حفظ التوكن
          await prefs.setString('user_role', userRole); // الصلاحية

          // حفظ الاسم والإيميل
          await prefs.setString(
            'first_name',
            responseData['first_name'] ?? 'مستخدم',
          );
          await prefs.setString('last_name', responseData['last_name'] ?? '');
          await prefs.setString('user_email', responseData['email'] ?? email);

          // حفظ رقم الهاتف والمدينة والمحفظة (إن كانت مرسلة من السيرفر)
          if (responseData['phone'] != null) {
            await prefs.setString(
              'user_phone',
              responseData['phone'].toString(),
            );
          }
          if (responseData['city'] != null) {
            await prefs.setString('user_city', responseData['city'].toString());
          }
          if (responseData['wallet_balance'] != null) {
            await prefs.setDouble(
              'wallet_balance',
              double.tryParse(responseData['wallet_balance'].toString()) ?? 0.0,
            );
          }

          _showSnackBar('تم تسجيل الدخول بنجاح 🚀', Colors.green);

          // التوجيه الذكي بناءً على دور المستخدم
          _navigateBasedOnRole(userRole);
        } else {
          _showSnackBar(
            'تم الدخول ولكن لم يتم استلام رمز المصادقة (Token).',
            Colors.orange,
          );
        }
      } else {
        _showSnackBar(
          'فشل تسجيل الدخول. تأكد من صحة البيانات.',
          Colors.redAccent,
        );
      }
    } catch (e) {
      debugPrint("❌ LOGIN ERROR: $e");
      if (!mounted) return;
      _showSnackBar('خطأ في الاتصال أو بيانات غير صحيحة.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🚀 دالة التوجيه الموجهة حسب نوع الحساب
  void _navigateBasedOnRole(String role) {
    Widget targetScreen;

    switch (role) {
      case 'store_admin':
      case 'merchant':
        targetScreen = const MainLayout(isGuest: false);
        break;

      case 'driver':
        targetScreen = const MainLayout(isGuest: false);
        break;

      case 'customer':
      default:
        targetScreen = const MainLayout(isGuest: false);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  void _handleGuestLogin() {
    _showSnackBar('تم الدخول كزائر بنجاح، استمتع بالتصفح 🛍️', AppTheme.gold);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainLayout(isGuest: true)),
    );
  }

  void _handleForgotPassword() {
    _showSnackBar('جاري الانتقال لاستعادة كلمة المرور...', Colors.blueAccent);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🛍️ سوق جو',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'سجل دخولك لتكتشف أفضل عروض التسوق',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppTheme.darkBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppTheme.darkBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text(
                      'هل نسيت كلمة المرور؟',
                      style: TextStyle(color: AppTheme.gold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
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
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleGuestLogin,
                  child: const Text(
                    'التسجيل كزائر (تصفح سريعة)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'أنشئ حساباً جديداً',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
