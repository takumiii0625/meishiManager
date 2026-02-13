import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/card_providers.dart';
import '../auth/auth_page.dart';
import 'card_add_page.dart';
import 'card_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class CardsPage extends ConsumerWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsStreamProvider);
    final authUserAsync = ref.watch(authStateChangesProvider);

    final isAnonymous = authUserAsync.maybeWhen(
      data: (u) => u?.isAnonymous == true,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('名刺一覧'),
        actions: [
          // 設定（ログイン/登録/リンク）画面へ
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: isAnonymous ? 'ログイン/引き継ぎ' : 'アカウント',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthPage()),
              );
            },
          ),

          // ログアウト（AuthGateがAuthPageに戻してくれる）
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ログアウト失敗: $e')),
                );
              }
            },
          ),
        ],
      ),

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
                    MaterialPageRoute(
                      builder: (_) => CardDetailPage(cardId: c.id),
                    ),
                  );
                },
                onLongPress: () async {
                  // ① まずユーザーに削除確認
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('削除しますか？'),
                      content: Text('「${c.name}」の名刺を削除します。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('削除'),
                        ),
                      ],
                    ),
                  );

                  // ② キャンセルなら何もしない
                  if (ok != true) return;

                  try {
                    // ③ uid を “今この瞬間” の値で取得（Providerの遅延/空を避ける）
                    final uid = ref.read(uidProvider);

                    // uid が空だと /users//cards になって絶対失敗するので、ここで止める
                    if (uid.isEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('削除できません：uidが取得できていません（ログイン直後の可能性）')),
                      );
                      return;
                    }

                    // ④ Firestoreへ直接 delete（これが一番確実）
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('cards')
                        .doc(c.id)
                        .delete();

                    // ⑤ 成功メッセージ
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('削除しました')),
                    );
                  } catch (e) {
                    // ⑥ 失敗したら必ず表示（「何も起きない」を潰す）
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('削除に失敗: $e')),
                    );
                  }
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
