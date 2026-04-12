// ============================================================
// add_tab_page.dart
// 「登録」タブの画面
//
// 【メニュー構成】
//   1. 名刺をスキャン → MultiScanPage（カメラ撮影 → 自動解析・保存）
//   2. 手動で登録    → CardAddPage（フォーム入力）
//
// 【画面の作りかた】
//   このファイルは「メニューを並べるだけ」のシンプルな画面。
//   実際の処理は各遷移先ページ（MultiScanPage / CardAddPage）が担当する。
// ============================================================

import 'package:flutter/material.dart';
import '../cards/card_add_page.dart';
import '../ocr/multi_scan_page.dart';

/// 登録タブのルート画面
/// StatelessWidget = 内部に状態を持たないシンプルな Widget
class AddTabPage extends StatelessWidget {
  const AddTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名刺を登録'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 名刺をスキャン（カメラOCR）────────────────────
          _MenuCard(
            icon: Icons.document_scanner,
            iconColor: const Color(0xFF1E40AF),
            title: '名刺をスキャン',
            subtitle: 'カメラで撮影 → 名刺情報を自動で読み取り・保存',
            badge: 'おすすめ',
            onTap: () {
              // MultiScanPage へ直接遷移
              // maxBatchSize は省略 → デフォルトの10枚が使われる
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MultiScanPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ── 手動で登録（フォーム入力）──────────────────────
          _MenuCard(
            icon: Icons.edit_note,
            iconColor: const Color(0xFF475569),
            title: '手動で登録',
            subtitle: '氏名・会社・電話などを手入力して追加',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardAddPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// メニューカード Widget
///
/// アイコン・タイトル・サブタイトル・任意バッジを持つカード型ボタン。
/// _MenuCard のように先頭に _ がついているクラスは「プライベート」で、
/// このファイルの中だけで使えるクラスを意味する。
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,       // 左側のアイコン
    required this.iconColor,  // アイコンの色
    required this.title,      // メインのテキスト
    required this.subtitle,   // 説明テキスト
    required this.onTap,      // タップしたときの処理
    this.badge,               // 「おすすめ」などのバッジ（省略可）
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap; // VoidCallback = 引数なし・戻り値なしの関数型
  final String? badge;      // null の場合はバッジを表示しない

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1, // カードの影の高さ
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // InkWell = タップしたときにリップルエフェクト（波紋）が出る Widget
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── アイコン背景 ──────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  // withOpacity(0.1) = 色を10%の透明度で表示（薄い背景色）
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),

              // ── テキスト部分 ─────────────────────────────
              // Expanded = 残りのスペースをすべて使う
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        // バッジ（badge が null でない場合だけ表示）
                        // ... = スプレッド演算子（リストの中にリストを展開する）
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,  // ! = null でないことを保証する（強制アンラップ）
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              // 右矢印アイコン（タップできることを示す）
              const Icon(Icons.chevron_right,
                  color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
