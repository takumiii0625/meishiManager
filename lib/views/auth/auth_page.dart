// ============================================================
// auth_page.dart
// ログイン / アカウント管理画面
//
// 【2つのモードを持つ画面】
//   1) 未ログイン時 → ログイン・新規登録・匿名ログインのフォームを表示
//   2) ログイン済み時 → アカウント情報表示・匿名→メール引き継ぎ・ログアウト
//
// 【なぜ1つの画面で2モード？】
//   ログイン状態は動的に変わるため（ログイン→ログアウトなど）、
//   authStateChangesProvider を watch して自動で切り替えるほうがシンプル。
//
// 【ConsumerStatefulWidget とは？】
//   Riverpod の ref が使えて、かつ自分で状態（_busy など）を持てる Widget。
//   StatefulWidget + ConsumerWidget を合わせたもの。
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  // フォームのバリデーション管理
  final _formKey = GlobalKey<FormState>();
  // テキストフィールドの入力値を管理するコントローラー
  final _email    = TextEditingController();
  final _password = TextEditingController();
  // 処理中フラグ（ボタンの二重タップを防ぐ）
  bool _busy = false;

  @override
  void dispose() {
    // コントローラーは画面が破棄されるときに必ず解放する（メモリリーク防止）
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// メールアドレスのバリデーション（入力チェック）
  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'メールは必須です';
    // 正規表現 = メールアドレスの形式かどうかチェックするパターン
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'メール形式が正しくありません';
  }

  /// パスワードのバリデーション
  String? _pwValidator(String? v) {
    final s = v ?? '';
    if (s.length < 6) return 'パスワードは6文字以上';
    return null;
  }

  /// フォームの入力値を EmailAuthParams にまとめるヘルパー
  EmailAuthParams _params() => EmailAuthParams(
        email: _email.text.trim(),    // trim() = 前後の空白を除去
        password: _password.text,
      );

  /// 非同期処理（ログイン・登録など）を共通化したヘルパー
  ///
  /// [validate] = フォームバリデーションを実行するかどうか
  /// [action]   = 実際に実行したい非同期処理
  Future<void> _run({
    bool validate = true,
    required Future<void> Function() action,
  }) async {
    if (_busy) return; // 処理中なら無視
    // バリデーションが必要な場合は、失敗したら処理を中断
    if (validate && !_formKey.currentState!.validate()) return;

    setState(() => _busy = true); // ローディング状態にする
    try {
      await action(); // 実際の処理を実行
    } catch (e) {
      // エラーが起きたらスナックバーで通知
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('失敗: $e')),
      );
    } finally {
      // 成功・失敗どちらでも _busy を戻す
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ログイン状態をリアルタイムで監視
    // user == null → 未ログイン、user != null → ログイン済み
    final authUserAsync = ref.watch(authStateChangesProvider);

    return authUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('アカウント')),
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) {
        // ════════════════════════════════════════════════
        // モード1：未ログイン → ログイン / 新規登録フォーム
        // ════════════════════════════════════════════════
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ログイン')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'メールでログイン / 新規登録できます。\n'
                    'まず試したい場合は「匿名で続ける」もOKです。',
                  ),
                  const SizedBox(height: 16),

                  // メール・パスワード入力フォーム
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'メール'),
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration:
                              const InputDecoration(labelText: 'パスワード（6文字以上）'),
                          obscureText: true, // パスワードを隠す
                          validator: _pwValidator,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // メールでログインボタン
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              action: () async {
                                await ref.read(
                                  signInWithEmailProvider(_params()).future,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ログインしました')),
                                );
                              },
                            ),
                    child: Text(_busy ? '処理中...' : 'メールでログイン'),
                  ),

                  const SizedBox(height: 12),

                  // メールで新規登録ボタン
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              action: () async {
                                await ref.read(
                                  signUpWithEmailProvider(_params()).future,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('新規登録しました')),
                                );
                              },
                            ),
                    child: const Text('メールで新規登録'),
                  ),

                  const SizedBox(height: 20),

                  // 匿名ログインボタン（メールなしで使い始める）
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              validate: false, // バリデーション不要
                              action: () async {
                                await ref.read(anonymousSignInProvider.future);
                                if (mounted) Navigator.of(context).pop();
                              },
                            ),
                    child: const Text('匿名で続ける'),
                  ),
                ],
              ),
            ),
          );
        }

        // ════════════════════════════════════════════════
        // モード2：ログイン済み → アカウント管理画面
        // ════════════════════════════════════════════════
        final isAnonymous = user.isAnonymous; // 匿名ユーザーかどうか
        final email = user.email ?? '';

        return Scaffold(
          appBar: AppBar(title: const Text('アカウント')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ログイン状態の表示
                Text(
                  isAnonymous ? '現在：匿名ログイン' : '現在：メールログイン',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('uid: ${user.uid}'),
                // メールログインの場合はメールアドレスも表示
                if (!isAnonymous) ...[
                  const SizedBox(height: 8),
                  Text('email: $email'),
                ],

                const Divider(height: 32),

                // 匿名ユーザーだけに表示：メールへの引き継ぎフォーム
                if (isAnonymous) ...[
                  const Text(
                    '匿名で作ったデータを、そのままメールアカウントに引き継げます（uidが変わらない）',
                  ),
                  const SizedBox(height: 16),

                  // メール・パスワードフォーム
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'メール'),
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration:
                              const InputDecoration(labelText: 'パスワード（6文字以上）'),
                          obscureText: true,
                          validator: _pwValidator,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // データ引き継ぎボタン（匿名 → メール）
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              action: () async {
                                await ref.read(
                                  linkEmailProvider(_params()).future,
                                );
                                if (mounted) Navigator.of(context).pop();
                              },
                            ),
                    icon: const Icon(Icons.link),
                    label: Text(_busy ? '処理中...' : 'データを引き継ぐ（匿名→メール）'),
                  ),

                  const Divider(height: 32),
                ],

                // ログアウトボタン（全ユーザー共通）
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                            validate: false,
                            action: () async {
                              await ref.read(signOutProvider.future);
                              if (mounted) Navigator.of(context).pop();
                            },
                          ),
                  child: Text(_busy ? '処理中...' : 'ログアウト'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
