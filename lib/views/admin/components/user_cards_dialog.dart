import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_providers.dart';
import 'admin_theme.dart';

class UserCardsDialog extends ConsumerWidget {
  const UserCardsDialog({super.key, required this.userDoc});

  final DocumentSnapshot userDoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data     = userDoc.data() as Map<String, dynamic>;
    final userName = data['name'] as String? ?? '不明';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$userName の名刺一覧',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.textMain)),
                      const SizedBox(height: 4),
                      const Text('※ 閲覧ログが記録されます',
                          style:
                              TextStyle(fontSize: 11, color: AdminColors.red)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminColors.textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ログ通知バナー ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEA),
                border: Border.all(color: const Color(0xFFF6D860)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: Color(0xFF92700A)),
                  SizedBox(width: 8),
                  Text(
                    'このアクセスは admin_access_logs に記録されました',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92700A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 名刺グリッド ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ref
                    .read(adminUsersViewModelProvider)
                    .watchBusinessCards(userDoc.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AdminColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('エラー: ${snapshot.error}',
                            style:
                                const TextStyle(color: AdminColors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('名刺データがありません',
                          style: TextStyle(color: AdminColors.textSub)),
                    );
                  }

                  final cards = snapshot.data!.docs;
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 150,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, i) {
                      final c = cards[i].data() as Map<String, dynamic>;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminColors.bg,
                          border: Border.all(color: AdminColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AdminColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (c['name'] as String? ?? '?')
                                          .isNotEmpty
                                          ? (c['name'] as String)[0]
                                          : '?',
                                      style: const TextStyle(
                                        color: AdminColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c['name'] as String? ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AdminColors.textMain),
                                          overflow: TextOverflow.ellipsis),
                                      Text(c['company'] as String? ?? '',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AdminColors.textSub),
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (c['email'] != null)
                              Text('📧 ${c['email']}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AdminColors.textMid),
                                  overflow: TextOverflow.ellipsis),
                            if (c['phone'] != null)
                              Text('📞 ${c['phone']}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AdminColors.textMid)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
