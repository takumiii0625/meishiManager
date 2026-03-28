// ============================================================
// auth_gate.dart
// ログイン状態を監視して、画面を切り替えるWidget
//
// 【役割】
//   アプリ起動時にログイン状態を確認し、
//   - 未ログイン → 匿名ログインを実行
//   - ログイン済み → HomeShell（メイン画面）を表示
//
// 【匿名ログインとは？】
//   メールアドレスやパスワードなしで Firebase Auth にログインする方法。
//   ユーザーが意識せずに使い始められる。
//   将来メールアドレスと紐づけることで「昇格」できる。
//
// 【ConsumerWidget とは？】
//   Riverpod の ref（プロバイダーへのアクセス手段）が使える StatelessWidget。
//   ref.watch() でプロバイダーの値を監視し、変化したら自動で再描画される。
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'views/home/home_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 未ログインなら匿名ログインを発火する
    // watch しているので、ログイン完了時に自動で再描画される
    ref.watch(anonymousSignInProvider);

    // Firebase Auth のログイン状態をリアルタイムで監視
    final authState = ref.watch(authStateChangesProvider);

    // authState.when() = 読み込み中 / エラー / データあり の3パターンに分岐
    return authState.when(
      // まだ状態が確定していない間はローディング表示
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // エラーが起きた場合はエラーメッセージを表示
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      // 状態が確定した場合
      data: (user) {
        if (user == null) {
          // 匿名ログインがまだ完了していない瞬間だけここに入る
          // 通常は一瞬で終わるため、ユーザーにはほぼ見えない
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 匿名ログインでも正規ログインでも、ユーザーがいればメイン画面へ
        return const HomeShell();
      },
    );
  }
}
