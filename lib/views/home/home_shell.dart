// ============================================================
// home_shell.dart
// アプリの「外枠」となる画面
//
// 【役割】
//   BottomNavigationBar（画面下のタブバー）を表示し、
//   タブの切り替えを管理する。
//
// 【タブ構成】
//   0: 一覧（SearchTabPage）→ 名刺の一覧・検索
//   1: 登録（AddTabPage）   → 手動登録・スキャン登録
//   2: 管理（SettingsTabPage）→ アカウント設定など
//
// 【IndexedStack とは？】
//   複数のWidgetを重ねて表示し、1つだけ表示する仕組み。
//   タブを切り替えても、各タブの状態（スクロール位置など）が
//   リセットされない。
//
// 【各タブに独立したNavigatorを持たせる理由】
//   タブAで詳細画面を開いた状態でタブBに移動し、またタブAに戻ると
//   詳細画面が残っている、という動きを実現するため。
// ============================================================

import 'package:flutter/material.dart';

import '../search/search_tab_page.dart';
import '../add/add_tab_page.dart';
import '../settings/settings_tab_page.dart';

/// アプリの「土台」となるWidget
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// 現在選択中のタブIndex（0=一覧, 1=登録, 2=管理）
  int _index = 0;

  /// 各タブ用のNavigatorキー
  /// GlobalKey<NavigatorState> = 特定のNavigatorを外から操作するための鍵
  /// タブごとに別々の遷移履歴を持てる
  final _navKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());

  /// タブIndexに対応するルートWidgetを返す
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

  /// タブをタップしたときの処理
  ///
  /// 同じタブを再タップ → そのタブのスタックをルートに戻す
  ///   （例: 詳細画面を開いた状態でタブを再タップすると一覧に戻る）
  /// 別のタブをタップ → そのタブに切り替える
  void _onTap(int newIndex) {
    if (newIndex == _index) {
      // popUntil((route) => route.isFirst) = ルートスタックの一番下まで戻る
      _navKeys[newIndex].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index, // 表示するタブのIndex
        // 3つのタブそれぞれに独立したNavigatorを持たせる
        children: List.generate(3, (i) {
          return Navigator(
            key: _navKeys[i], // このNavigatorを外から操作するための鍵
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => _rootForIndex(i),
                settings: settings,
              );
            },
          );
        }),
      ),
      // 画面下のタブバー
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
