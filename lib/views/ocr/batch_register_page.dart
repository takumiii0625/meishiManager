// lib/views/ocr/batch_register_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'batch_analyze_page.dart';
import 'multi_scan_page.dart';
import 'scan_step.dart';

class BatchRegisterPage extends StatelessWidget {
  const BatchRegisterPage({super.key});

  Future<void> _openScanner(BuildContext context) async {
    // MultiScanPage をpushして、popで返ってきた結果を受け取る
    final results = await Navigator.push<List<CardScanResult>>(
      context,
      MaterialPageRoute(
        builder: (_) => const MultiScanPage(maxBatchSize: 5),
      ),
    );

    // results が null = 何も撮影せずに戻った
    if (results == null || results.isEmpty) return;
    if (!context.mounted) return;

    // BatchAnalyzePage へ遷移して解析・保存
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BatchAnalyzePage(scanResults: results),
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
        onPressed: () => _openScanner(context),
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
              child: Text(
                'まだ名刺がありません。\n右下の「連続スキャン開始」から登録してください。',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final card =
                  (data['card'] as Map?)?.cast<String, dynamic>() ??
                      <String, dynamic>{};

              final company = card['company'] as String? ??
                  (data['company'] as String? ?? '');
              final nameJa = card['name_ja'] as String? ?? '';
              final nameEn = card['name_en'] as String? ?? '';
              final name = (data['name'] as String?) ??
                  (nameJa.isNotEmpty ? nameJa : nameEn);

              final imageUrl =
                  (data['frontImageUrl'] as String?)?.isNotEmpty == true
                      ? data['frontImageUrl'] as String
                      : (data['imageUrl'] as String? ?? '');

              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 20),
                        )
                      : const Icon(Icons.credit_card, color: Colors.grey),
                ),
                title: Text(company.isNotEmpty ? company : '(会社名なし)'),
                subtitle: Text(
                  [name, nameEn]
                      .where((e) => e.trim().isNotEmpty)
                      .join(' / '),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
