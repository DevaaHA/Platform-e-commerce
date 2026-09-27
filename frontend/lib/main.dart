import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/verify_otp_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/products/presentation/screens/home_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/dashboard/presentation/screens/users_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('app_dark_mode') ?? true;
  final String savedLang = prefs.getString('app_language') ?? 'العربية';

  runApp(SouqJoApp(isDarkMode: isDarkMode, savedLang: savedLang));
}

class SouqJoApp extends StatelessWidget {
  final bool isDarkMode;
  final String savedLang;

  // جعل المعاملات اختيارية بقيم افتراضية لضمان عمل اختبارات الويدجت (widget_test.dart) بدون أخطاء
  const SouqJoApp({
    super.key,
    this.isDarkMode = true,
    this.savedLang = 'العربية',
  });

  @override
  Widget build(BuildContext context) {
    final Locale initialLocale = savedLang == 'English'
        ? const Locale('en', 'US')
        : const Locale('ar', 'JO');

    return MaterialApp(
      title: 'سوق جو - SouqJo',
      debugShowCheckedModeBanner: false,
      locale: initialLocale,
      supportedLocales: const [Locale('ar', 'JO'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-otp': (context) => const VerifyOtpScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/home': (context) => const HomeScreen(),
        '/dashboard/users': (context) => const UsersManagementScreen(),
      },
    );
  }
}
