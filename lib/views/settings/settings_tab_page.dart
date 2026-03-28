// ============================================================
// settings_tab_page.dart
// 「管理」タブの画面
//
// 【メニュー構成】
//   1. ログイン情報の表示（uid確認）
//   2. メールログインを有効化（匿名 → メールに紐づけ）
//   3. ログアウト
//
// 【匿名アカウントとメールアカウントの違い】
//   匿名：アプリをインストールした端末でしか使えない
//   メール紐づけ後：別の端末やアプリ再インストール後もデータが残る
//   ※ 紐づけすると uid は変わらないので名刺データはそのまま引き継げる
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../auth/link_email_page.dart';

/// 管理タブの Widget
/// ConsumerWidget = Riverpod の ref が使える StatelessWidget
class SettingsTabPage extends ConsumerWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在ログイン中のユーザーの uid を取得（デバッグ・確認用）
    final uid = ref.watch(uidProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── ログイン情報 ─────────────────────────────────
          // uid を表示することで「どのユーザーでログインしているか」がわかる
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('ログイン情報'),
              // uid が空なら取得中、あれば表示する
              subtitle: Text(uid.isEmpty ? '取得中...' : 'uid: $uid'),
            ),
          ),
          const SizedBox(height: 12),

          // ── メールログインを有効化 ───────────────────────
          // 匿名ユーザーのままだとアプリを削除するとデータが消える。
          // メールを紐づけることで、別端末でもログインできるようになる。
          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: const Text('メールログインを有効化'),
              subtitle: const Text('匿名アカウントをメールに紐づけ'),
              onTap: () {
                // LinkEmailPage = メール紐づけ用フォーム画面
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LinkEmailPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── ログアウト ───────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () async {
                // まず確認ダイアログを表示する
                final ok = await _confirmSignOut(context);
                // キャンセルされた場合は何もしない
                if (ok != true) return;

                try {
                  // signOutProvider = ログアウトを実行する Provider
                  // .future = 完了するまで待つ
                  await ref.read(signOutProvider.future);

                  // mounted チェック = 非同期処理中に画面が閉じられていないか確認
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ログアウトしました')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ログアウト失敗: $e')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ログアウト確認ダイアログを表示する
  ///
  /// showDialog = 画面の上にダイアログを重ねて表示する
  /// Future<bool?> = 「はい」か「いいえ」か「キャンセル」が返ってくる
  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('匿名アカウントで作成したデータは、同じ端末でも新しい匿名ユーザーになると見えなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // キャンセル
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), // 実行
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}
