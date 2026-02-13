import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../auth/link_email_page.dart';

/// 管理タブ
/// - メールログインを有効化（匿名→メール紐付け）
/// - ログアウト
class SettingsTabPage extends ConsumerWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // uid表示（デバッグ用に便利）
    final uid = ref.watch(uidProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // いまのログイン状態をざっくり表示（管理アプリ感）
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('ログイン情報'),
              subtitle: Text(uid.isEmpty ? '取得中...' : 'uid: $uid'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: const Text('メールログインを有効化'),
              subtitle: const Text('匿名アカウントをメールに紐づけ'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LinkEmailPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () async {
                final ok = await _confirmSignOut(context);
                if (ok != true) return;

                try {
                  await ref.read(signOutProvider.future);

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

  /// ログアウト確認ダイアログ
  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('匿名アカウントで作成したデータは、同じ端末でも新しい匿名ユーザーになると見えなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}
