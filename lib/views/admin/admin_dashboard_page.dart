import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_dashboard_content.dart';
import 'admin_settings_page.dart';
import 'admin_users_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardContent(), // 0: ダッシュボード
    const AdminUsersPage(),        // 1: ユーザー管理
    const AdminSettingsPage(),     // 2: 設定
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── サイドバー ──
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIconTheme:
                const IconThemeData(color: Color(0xFF4361EE)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF4361EE),
              fontWeight: FontWeight.w700,
            ),
            unselectedIconTheme:
                const IconThemeData(color: Color(0xFF9396A5)),
            unselectedLabelTextStyle:
                const TextStyle(color: Color(0xFF9396A5)),
            indicatorColor: const Color(0xFFEEF1FD),
            extended: MediaQuery.of(context).size.width >= 900,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('ダッシュボード')),
              NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('ユーザー管理')),
              NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('設定')),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // ── メインコンテンツ ──
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}