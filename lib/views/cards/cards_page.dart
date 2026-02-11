import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/card_providers.dart';
import 'card_add_page.dart';
import 'card_detail_page.dart';

class CardsPage extends ConsumerWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('名刺一覧')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CardAddPage()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('まだ名刺がありません'));
          }
          return ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = cards[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text('${c.company} / ${c.email}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CardDetailPage(cardId: c.id)),
                  );
                },
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('削除しますか？'),
                      content: Text('「${c.name}」の名刺を削除します。'),
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

                  // 即反映方針：awaitしない（同期完了待ちで固まらない）
                  final uid = ref.read(uidProvider);
                  ref.read(cardRepositoryProvider).deleteCard(uid, c.id);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('削除しました')),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}
