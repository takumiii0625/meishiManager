import 'package:flutter/material.dart';
import 'admin_users_page.dart'; // ユーザー管理ページをインポート

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // 現在表示しているページのインデックス
  int _selectedIndex = 0;

  // 表示する画面のリスト
  final List<Widget> _pages = [
    const Center(child: Text('ダッシュボード概要（統計など）')), // 0: ダッシュボード
    const AdminUsersPage(),                             // 1: ユーザー管理（ここを追加！）
    const Center(child: Text('設定画面（準備中）')),         // 2: 設定
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // --- サイドバー ---
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: Color(0xFF4361EE)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF4361EE),
              fontWeight: FontWeight.w700,
            ),
            unselectedIconTheme: const IconThemeData(color: Color(0xFF9396A5)),
            unselectedLabelTextStyle: const TextStyle(color: Color(0xFF9396A5)),
            indicatorColor: const Color(0xFFEEF1FD),
            extended: MediaQuery.of(context).size.width >= 900,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('ダッシュボード')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('ユーザー管理')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('設定')),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // --- メインコンテンツ ---
          Expanded(
            child: Column(
              children: [
                // ✅ ここでリストから現在のページを呼び出す
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ページタイトルを返すヘルパー関数
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return '管理ダッシュボード';
      case 1: return 'ユーザー管理';
      case 2: return '設定';
      default: return '管理画面';
    }
  }
}