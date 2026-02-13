import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'メールは必須です';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'メール形式が正しくありません';
  }

  String? _pwValidator(String? v) {
    final s = v ?? '';
    if (s.length < 6) return 'パスワードは6文字以上';
    return null;
  }

  EmailAuthParams _params() => EmailAuthParams(
        email: _email.text.trim(),
        password: _password.text,
      );

  Future<void> _run({
    bool validate = true,
    required Future<void> Function() action,
  }) async {
    if (_busy) return;
    if (validate && !_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // =========================
        // 1) 未ログイン：ログイン画面
        // =========================
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

                  const SizedBox(height: 20),

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

                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              validate: false,
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

        // =========================
        // 2) ログイン済み：アカウント管理
        // =========================
        final isAnonymous = user.isAnonymous;
        final email = user.email ?? '';

        return Scaffold(
          appBar: AppBar(title: const Text('アカウント')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  isAnonymous ? '現在：匿名ログイン' : '現在：メールログイン',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('uid: ${user.uid}'),
                if (!isAnonymous) ...[
                  const SizedBox(height: 8),
                  Text('email: $email'),
                ],

                const Divider(height: 32),

                // ---- 匿名のときだけ：引き継ぎ（リンク）
                if (isAnonymous) ...[
                  const Text(
                    '匿名で作ったデータを、そのままメールアカウントに引き継げます（uidが変わらない）',
                  ),
                  const SizedBox(height: 16),

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

                // ---- 共通：ログアウト
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
