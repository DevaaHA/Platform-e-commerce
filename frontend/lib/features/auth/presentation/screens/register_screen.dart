import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'customer';
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty) {
      _showSnackBar('الرجاء تعبئة كافة الحقول الأساسية', Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'role': _selectedRole,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(
          'تم إنشاء الحساب بنجاح، يمكنك تسجيل الدخول الآن 🚀',
          Colors.green,
        );
        // ننتظر ثانية ثم نعود لصفحة الدخول
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackBar('فشل التسجيل. تأكد من صحة البيانات.', Colors.redAccent);
      }
    } catch (e) {
      if (!mounted) return;
      // 🚀 تم تحسين رسالة الخطأ لتذكير المستخدم بمشكلة تكرار رقم الهاتف
      _showSnackBar(
        'البيانات مرفوضة (400)! تأكد أن البريد الإلكتروني أو "رقم الهاتف" غير مستخدمين في حساب آخر.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: const Text(
          'إنشاء حساب جديد - سوق جو',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
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
                  'انضم إلى سوق جو 🚀',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'أنشئ حسابك واستمتع بأقوى تجربة تسوق',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('الاسم الأول'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('اسم العائلة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('البريد الإلكتروني'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'رقم الهاتف (لا تكرر رقم حسابك القديم)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'كلمة المرور (8 أحرف على الأقل)',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true, // 🚀 هذا هو الحل السحري لانهيار الواجهة
                      value: _selectedRole,
                      dropdownColor: AppTheme.surfaceDark,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: 'customer',
                          child: Text('مشتري (Customer)'),
                        ),
                        DropdownMenuItem(
                          value: 'store_admin',
                          child: Text('تاجر / صاحب متجر (Store Owner)'),
                        ),
                        DropdownMenuItem(
                          value: 'driver',
                          child: Text('كابتن توصيل (Driver)'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedRole = val ?? 'customer'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'تسجيل الحساب',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppTheme.darkBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
