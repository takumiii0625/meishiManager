// ============================================================
// settings_tab_page.dart
// 「管理」タブの画面
//
// 【メニュー構成】
//   1. プロフィール（詳細・編集画面へ）
//   2. SNSアカウントと連携する
//   3. アプリ設定（メールアプリ選択）
//   4. ログアウト
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/web_auth_provider.dart';
import '../../services/mail_app_service.dart';
import 'profile_page.dart';

class SettingsTabPage extends ConsumerWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final linkedProviders = userAsync.maybeWhen(
      data: (user) => user?.providerData.map((p) => p.providerId).toSet() ?? {},
      orElse: () => <String>{},
    );

    final isGoogleLinked   = linkedProviders.contains('google.com');
    final isFacebookLinked = linkedProviders.contains('facebook.com');
    final isTwitterLinked  = linkedProviders.contains('twitter.com');

    return Scaffold(
      appBar: AppBar(title: const Text('管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── プロフィール ──────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('プロフィール'),
              subtitle: Text(
                userAsync.maybeWhen(
                  data: (u) => u?.email ?? 'メール未設定',
                  orElse: () => '取得中...',
                ),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: Color(0xFFCBD5E1), size: 20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── SNS連携 ───────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'SNSアカウントと連携する',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B)),
            ),
          ),

          _SnsLinkTile(
            icon: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8EAF0)),
              ),
              child: const Center(
                child: Text('G',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Color(0xFFDB4437))),
              ),
            ),
            title: 'Google',
            isLinked: isGoogleLinked,
            onTap: isGoogleLinked ? null : () => _linkWithGoogle(context, ref),
          ),
          const SizedBox(height: 8),

          _SnsLinkTile(
            icon: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('f',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
            title: 'Facebook',
            isLinked: isFacebookLinked,
            onTap: isFacebookLinked ? null : () => _linkWithFacebook(context, ref),
          ),
          const SizedBox(height: 8),

          _SnsLinkTile(
            icon: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('𝕏',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
            title: 'X（Twitter）',
            isLinked: isTwitterLinked,
            onTap: isTwitterLinked ? null : () => _linkWithTwitter(context, ref),
          ),
          const SizedBox(height: 12),

          // ── アプリ設定 ────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'アプリ設定',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B)),
            ),
          ),

          // メールアプリ選択タイル
          _MailAppTile(parentContext: context, ref: ref),
          const SizedBox(height: 12),

          // ── ログアウト ────────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _linkWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(webAuthViewModelProvider).linkWithGoogle();
      if (!context.mounted) return;
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Googleアカウントと連携しました')));
      } else {
        final err = ref.read(webAuthViewModelProvider).errorMessage;
        if (err != null) ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google連携に失敗しました: $e')));
    }
  }

  Future<void> _linkWithFacebook(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(webAuthViewModelProvider).linkWithFacebook();
      if (!context.mounted) return;
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facebookアカウントと連携しました')));
      } else {
        final err = ref.read(webAuthViewModelProvider).errorMessage;
        if (err != null) ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook連携に失敗しました: $e')));
    }
  }

  Future<void> _linkWithTwitter(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(webAuthViewModelProvider).linkWithTwitter();
      if (!context.mounted) return;
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xアカウントと連携しました')));
      } else {
        final err = ref.read(webAuthViewModelProvider).errorMessage;
        if (err != null) ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('X連携に失敗しました: $e')));
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('ログアウトすると再度ログインが必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(signOutProvider.future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログアウトしました')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウト失敗: $e')));
    }
  }
}

// ── メールアプリ選択タイル ────────────────────────────────
class _MailAppTile extends StatelessWidget {
  const _MailAppTile({required this.parentContext, required this.ref});
  final BuildContext parentContext;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // 現在選択中のメールアプリ
    final selectedApp = ref.watch(selectedMailAppProvider);
    // 端末にインストール済みのアプリ一覧
    final installedApps = ref.watch(installedMailAppsProvider);

    final currentName = selectedApp.maybeWhen(
      data: (app) => app.name,
      orElse: () => '取得中...',
    );

    return Card(
      child: ListTile(
        leading: const Icon(Icons.mail_outline, color: Color(0xFF1E40AF)),
        title: const Text('メールアプリ'),
        subtitle: Text(currentName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right,
            color: Color(0xFFCBD5E1), size: 20),
        onTap: () => _showMailAppPicker(context, installedApps),
      ),
    );
  }

  /// メールアプリ選択ダイアログ
  void _showMailAppPicker(
      BuildContext context, AsyncValue<List<MailApp>> installedApps) {
    installedApps.whenData((apps) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('メールアプリを選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: apps.map((app) {
              // 現在選択中かどうか
              final isSelected = ref.read(selectedMailAppProvider).maybeWhen(
                    data: (selected) => selected.id == app.id,
                    orElse: () => false,
                  );
              return ListTile(
                title: Text(app.name),
                leading: Icon(
                  Icons.mail_outline,
                  color: isSelected
                      ? const Color(0xFF1E40AF)
                      : const Color(0xFF94A3B8),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF1E40AF), size: 18)
                    : null,
                onTap: () async {
                  Navigator.pop(dialogContext);
                  // 選択を保存
                  await ref
                      .read(selectedMailAppProvider.notifier)
                      .select(app);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${app.name} を設定しました')),
                  );
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      );
    });
  }
}

// ── SNS連携タイル ─────────────────────────────────────────
class _SnsLinkTile extends StatelessWidget {
  const _SnsLinkTile({
    required this.icon,
    required this.title,
    required this.isLinked,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final bool isLinked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            color: isLinked
                ? const Color(0xFF94A3B8)
                : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          isLinked ? '連携済み' : '${title}アカウントと紐づける',
          style: TextStyle(
            fontSize: 12,
            color: isLinked
                ? const Color(0xFF22C55E)
                : const Color(0xFF94A3B8),
          ),
        ),
        trailing: isLinked
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Color(0xFF22C55E)),
                    SizedBox(width: 4),
                    Text('連携済み',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : const Icon(Icons.chevron_right,
                color: Color(0xFFCBD5E1), size: 20),
        onTap: onTap,
      ),
    );
  }
}
