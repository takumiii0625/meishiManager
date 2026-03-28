// ============================================================
// search_tab_page.dart
// 「一覧」タブのルート画面
//
// 【役割】
//   BottomNavigationBar の「一覧」タブを押したときに表示される画面。
//   現在は CardsPage（名刺一覧）をそのまま表示しているだけ。
//
// 【なぜ別ファイルにしているか？】
//   HomeShell（タブ管理）と CardsPage（一覧ロジック）を分離するため。
//   将来タブに「絞り込みバー」などを追加する際にここを修正する。
// ============================================================

import 'package:flutter/material.dart';
import '../cards/cards_page.dart';

/// 一覧（検索）タブのルート Widget
/// StatelessWidget = 内部に状態を持たないシンプルな Widget
class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CardsPage（名刺一覧画面）をそのまま表示する
    return const CardsPage();
  }
}
