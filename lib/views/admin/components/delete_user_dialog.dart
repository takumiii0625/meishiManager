import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_providers.dart';
import 'admin_theme.dart';

class DeleteUserDialog extends ConsumerWidget {
  const DeleteUserDialog({super.key, required this.doc});

  final DocumentSnapshot doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data     = doc.data() as Map<String, dynamic>;
    final userName = data['name'] as String? ?? '不明';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('ユーザーを削除しますか？',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textMain)),
            const SizedBox(height: 8),
            Text(
              '$userName を削除すると、登録された名刺データもすべて削除されます。この操作は取り消せません。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AdminColors.textSub, height: 1.7),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AdminColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('キャンセル',
                      style: TextStyle(color: AdminColors.textSub)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(adminUsersViewModelProvider).deleteUser(
                      userId:   doc.id,
                      userName: userName,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$userName を削除しました'),
                        backgroundColor: AdminColors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.red,
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
