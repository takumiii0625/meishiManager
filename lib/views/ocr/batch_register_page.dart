// lib/views/ocr/batch_register_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/business_card_service.dart';
import 'ocr_scan_page.dart';

/// OCR連続登録 + 一覧確認画面
/// ✅ /users/{uid}/cards をリアルタイム表示
/// ✅ 「連続スキャン開始」→ OcrScanPage → 保存 → 件数をSnackBarで表示
class BatchRegisterPage extends StatefulWidget {
  const BatchRegisterPage({super.key});

  @override
  State<BatchRegisterPage> createState() => _BatchRegisterPageState();
}

class _BatchRegisterPageState extends State<BatchRegisterPage> {
  final BusinessCardService _svc = BusinessCardService();
  int _savedCount = 0;

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OcrScanPage(
          onCaptured: (card, rawText, imagePath) async {
            final docId = await _svc.addCard(
              card: card,
              rawText: rawText,
              imagePath: imagePath,
            );

            if (!mounted) return;
            setState(() => _savedCount++);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存しました（$_savedCount 件目 / docId: $docId）')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cards')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('OCR連続登録（一覧）')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        icon: const Icon(Icons.document_scanner),
        label: const Text('連続スキャン開始'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('まだ名刺がありません。\n右下の「連続スキャン開始」から登録してください。'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final data = docs[i].data();

              // ✅ cardが無くても落ちない
              final card = (data['card'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

              // ✅ null is not a subtype of String 対策
              final company = card['company'] as String? ?? (data['company'] as String? ?? '');
              final nameJa  = card['name_ja'] as String? ?? '';
              final nameEn  = card['name_en'] as String? ?? '';
              final name    = (data['name'] as String?) ?? (nameJa.isNotEmpty ? nameJa : nameEn);

              return ListTile(
                // 左側に画像を表示
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: data['imageUrl'] != null && data['imageUrl'] != ''
                      ? Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          // 読み込み中のエラー対策
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 20),
                        )
                      : const Icon(Icons.credit_card, color: Colors.grey),
                ),
                title: Text(company.isNotEmpty ? company : '(会社名なし)'),
                subtitle: Text([name, nameEn].where((e) => e.trim().isNotEmpty).join(' / ')),
              );
            },
          );
        },
      ),
    );
  }
}
