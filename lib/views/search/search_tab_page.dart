import 'package:flutter/material.dart';

import '../cards/cards_page.dart';

/// 一覧（検索）タブ
/// - 将来的に「検索バー」や「フィルタ」をここに足していく
class SearchTabPage extends StatelessWidget {
  const SearchTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 既存の名刺一覧画面を表示（まずは最短で統合）
    return const CardsPage();
  }
}
