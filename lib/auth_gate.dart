// ============================================================
// auth_gate.dart
// ログイン状態を監視して、画面を切り替えるWidget
//
// 【振り分けロジック】
//   未ログイン               → WebAuthPage（ログイン画面）
//   匿名ユーザー             → 強制ログアウト → WebAuthPage
//   Xログイン + メールなし   → EmailSetupPage（メール登録画面）
//                              ※ メール未登録なら起動のたびに表示される
//   上記以外のログイン済み   → HomeShell（メイン画面）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'views/auth/email_setup_page.dart';
import 'views/auth/web_auth_page.dart';
import 'views/home/home_shell.dart';

// メモリ上のスキップフラグ（今のセッションだけ有効）
// true にすると EmailSetupPage をスキップして HomeShell に進む
final emailSetupDoneProvider = StateProvider<bool>((ref) => false);

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState      = ref.watch(authStateChangesProvider);
    final emailSetupDone = ref.watch(emailSetupDoneProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const WebAuthPage(),
      data: (user) {
        // 未ログイン → ログイン画面へ
        if (user == null) return const WebAuthPage();

        // 匿名ユーザーが残っている場合は強制ログアウト → ログイン画面へ
        if (user.isAnonymous) {
          ref.read(firebaseAuthProvider).signOut();
          return const WebAuthPage();
        }

        // Xのみでログインかつメールなし → メール登録画面へ
        // emailSetupDone = true（今のセッションでスキップ or 登録済み）なら HomeShell へ
        final providerIds   = user.providerData.map((p) => p.providerId).toSet();
        final isTwitterOnly = providerIds.length == 1 &&
            providerIds.contains('twitter.com');
        final hasNoEmail    = user.email == null || user.email!.isEmpty;

        if (isTwitterOnly && hasNoEmail && !emailSetupDone) {
          return const EmailSetupPage();
        }

        // 正規ログイン済み → メイン画面へ
        return const HomeShell();
      },
    );
  }
}
