import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'admin_stores_screen.dart';
import 'admin_dashboard_screen.dart';

class SuperAdminMainDashboard extends StatefulWidget {
  const SuperAdminMainDashboard({super.key});

  @override
  State<SuperAdminMainDashboard> createState() =>
      _SuperAdminMainDashboardState();
}

class _SuperAdminMainDashboardState extends State<SuperAdminMainDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _adminPages = [
    const AdminDashboardScreen(),
    const AdminStoresScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Row(
        children: [
          // الشريط الجانبي الاحترافي (Sidebar)
          NavigationRail(
            backgroundColor: AppTheme.surfaceDark,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            selectedIconTheme: const IconThemeData(
              color: AppTheme.gold,
              size: 24,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppTheme.textMuted,
              size: 22,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AppTheme.gold,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppTheme.textMuted,
            ),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('الرئيسية'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: Text('المتاجر'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('المستخدمون'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.security_outlined),
                selectedIcon: Icon(Icons.security),
                label: Text('الصلاحيات'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
          // محتوى الصفحة الحالية
          Expanded(
            child: _selectedIndex < _adminPages.length
                ? _adminPages[_selectedIndex]
                : const Center(
                    child: Text(
                      'صفحة قيد التطوير الإداري',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
