import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/card_model.dart';
import '../../../providers/card_providers.dart';
import 'cards_theme.dart';

class DeleteCardDialog extends ConsumerWidget {
  const DeleteCardDialog({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('名刺を削除しますか？',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CardsColors.textMain)),
            const SizedBox(height: 8),
            Text(
              '${card.name}（${card.company}）の名刺を削除します。この操作は取り消せません。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: CardsColors.textSub, height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CardsColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('キャンセル',
                      style: TextStyle(color: CardsColors.textSub)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(deleteCardProvider(card.id).future);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${card.name} の名刺を削除しました'),
                        backgroundColor: CardsColors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CardsColors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('削除する',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
