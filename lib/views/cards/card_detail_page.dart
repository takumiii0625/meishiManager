import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/card_providers.dart';
import '../../models/card_model.dart';
import 'card_edit_page.dart';

class CardDetailPage extends ConsumerWidget {
  const CardDetailPage({super.key, required this.cardId});

  final String cardId;

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    CardModel card,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${card.name}」の名刺を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // await して確実に削除してから戻る（削除は待った方が安全）
      await ref.read(deleteCardProvider(card.id).future);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除しました')),
      );

      // 詳細 → 一覧へ戻る
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(cardStreamProvider(cardId));

    return cardAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('名刺詳細')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('名刺詳細')),
        body: Center(child: Text('エラー: $e')),
      ),
      data: (CardModel card) => Scaffold(
        appBar: AppBar(
          title: const Text('名刺詳細'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CardEditPage(card: card)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmAndDelete(context, ref, card),
              tooltip: '削除',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(card.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(card.company, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 32),
            _row('業種', card.industry),
            _row('電話', card.phone),
            _row('メール', card.email),
            _row('メモ', card.notes),
            const Divider(height: 32),
            _row('状態', card.status.name),
          ],
        ),
      ),
    );
  }
}
