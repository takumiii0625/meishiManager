import 'package:flutter/material.dart';

import '../search/search_tab_page.dart';
import '../add/add_tab_page.dart';
import '../settings/settings_tab_page.dart';

/// アプリの「土台」
/// - BottomNavigationBarで3タブを切り替える
/// - 各タブに専用Navigatorを持たせる（タブ内の遷移履歴を保持する）
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// 現在選択中のタブIndex
  int _index = 0;

  /// 各タブ用のNavigatorキー（タブごとに履歴を持つ）
  final _navKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());

  /// タブに表示するルートWidget（Navigatorの中で使う）
  Widget _rootForIndex(int index) {
    switch (index) {
      case 0:
        return const SearchTabPage(); // 一覧（検索）
      case 1:
        return const AddTabPage(); // 登録（手動/OCR）
      case 2:
        return const SettingsTabPage(); // 管理
      default:
        return const SearchTabPage();
    }
  }

  /// 同じタブを再タップしたら、そのタブのスタックをトップに戻す（よくある挙動）
  void _onTap(int newIndex) {
    if (newIndex == _index) {
      _navKeys[newIndex].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// IndexedStack でタブを切り替える
      /// - 子Widgetは破棄されないので、状態が保持される
      body: IndexedStack(
        index: _index,
        children: List.generate(3, (i) {
          return Navigator(
            key: _navKeys[i],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => _rootForIndex(i),
                settings: settings,
              );
            },
          );
        }),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: '登録',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '管理',
          ),
        ],
      ),
    );
  }
}
