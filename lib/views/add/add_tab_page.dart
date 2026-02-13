// lib/views/add/add_tab_page.dart
import 'package:flutter/material.dart';

import '../cards/card_add_page.dart';
import '../ocr/batch_register_page.dart';

/// 登録タブ
/// - 手動登録
/// - OCR連続登録（BatchRegisterPageを開く）
class AddTabPage extends StatelessWidget {
  const AddTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            icon: Icons.edit_document,
            title: '手動で登録',
            subtitle: '氏名/会社/業種などを入力して追加',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardAddPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.document_scanner,
            title: 'OCRで登録（連続）',
            subtitle: 'カメラで名刺を読み取り → 自動保存',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BatchRegisterPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// メニュー表示用の部品
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
