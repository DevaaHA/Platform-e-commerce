import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // من أجل الاهتزاز الخفيف (Haptic Feedback)
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'home_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../ai_fitting/presentation/screens/ai_fitting_room_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  final bool isGuest;

  const MainLayout({super.key, required this.isGuest});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  int _cartItemsCount = 0; // 🚀 رقم حقيقي للسلة
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRealCartCount(); // جلب عدد عناصر السلة الحقيقي عند فتح التطبيق
  }

  // 🚀 دالة فعلية لجلب عدد عناصر السلة من الباك إند
  Future<void> _fetchRealCartCount() async {
    try {
      final response = await _apiService.get(ApiConstants.cart);
      if (response.statusCode == 200 && response.data != null) {
        // حساب إجمالي الكميات داخل السلة بدقة
        int totalItems = 0;
        final items = response.data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          totalItems += (item['quantity'] as int? ?? 0);
        }
        if (mounted) {
          setState(() => _cartItemsCount = totalItems);
        }
      }
    } catch (e) {
      debugPrint("لم يتمكن من جلب السلة (قد تكون فارغة أو المستخدم زائر)");
    }
  }

  void _onTabTapped(int index) {
    // إضافة اهتزاز خفيف جداً يضيف إحساساً بالفخامة كالتطبيقات العالمية
    HapticFeedback.lightImpact();

    // منع الزائر من دخول السلة أو الملف الشخصي مباشرة
    if (widget.isGuest && (index == 2 || index == 3)) {
      _showGuestRestrictionDialog();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // تحديث رقم السلة في كل مرة يضغط فيها المستخدم على تبويب السلة
    if (index == 2 && !widget.isGuest) {
      _fetchRealCartCount();
    }
  }

  void _showGuestRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.gold),
            SizedBox(width: 8),
            Text(
              'تسجيل الدخول',
              style: TextStyle(color: AppTheme.gold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'هذه الميزة متاحة فقط للأعضاء المسجلين. هل ترغب في إنشاء حساب الآن للاستمتاع بكامل ميزات سوق جو؟',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.darkBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // قائمة الشاشات
    final List<Widget> screens = [
      const HomeScreen(),
      const AiFittingRoomScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      // 🚀 تم إزالة הـ AppBar من هنا!
      // لماذا؟ لكي تمتلك كل شاشة AppBar خاص بها (مثلاً الرئيسية فيها بحث، والبروفايل فيه إعدادات)
      // هذا هو الستاندرد العالمي في Amazon و Shein.

      // 🚀 IndexedStack: السر السحري للأداء!
      // يحافظ على حالة الشاشات. إذا نزلت لأسفل في الرئيسية ثم ذهبت للسلة، ستجد الرئيسية كما تركتها بالضبط ولن يتم تحميلها من الصفر.
      body: IndexedStack(index: _currentIndex, children: screens),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: AppTheme.surfaceDark,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: AppTheme.gold,
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home),
                ),
                label: 'الرئيسية',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.checkroom_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.checkroom),
                ),
                label: 'القياس الذكي',
              ),
              BottomNavigationBarItem(
                icon: _buildCartIcon(Icons.shopping_cart_outlined),
                activeIcon: _buildCartIcon(Icons.shopping_cart),
                label: 'السلة',
              ),
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person),
                ),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 ويدجت ديناميكية تبني أيقونة السلة مع الرقم الحقيقي (Badge)
  Widget _buildCartIcon(IconData iconData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(iconData),
          if (_cartItemsCount >
              0) // لا تظهر النقطة الحمراء إذا كانت السلة فارغة
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _cartItemsCount > 99
                      ? '99+'
                      : '$_cartItemsCount', // احترافية عرض الأرقام الكبيرة
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
