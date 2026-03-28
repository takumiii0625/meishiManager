// ============================================================
// link_email_page.dart
// 匿名アカウントをメールアドレスに紐づける画面
//
// 【役割】
//   settings_tab_page.dart の「メールログインを有効化」から開く。
//   メール・パスワードを入力して送信すると、
//   現在の匿名アカウントにメールが紐づく。
//
// 【紐づけのメリット】
//   匿名のままだと端末を変えたり、アプリを再インストールすると
//   データが見えなくなる。メールに紐づければ uid が変わらないので、
//   登録済みの名刺データをそのまま引き継げる。
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';

/// メール紐づけ画面の Widget
/// ConsumerStatefulWidget = ref が使えて、かつ自分で状態を持てる Widget
class LinkEmailPage extends ConsumerStatefulWidget {
  const LinkEmailPage({super.key});

  @override
  ConsumerState<LinkEmailPage> createState() => _LinkEmailPageState();
}

class _LinkEmailPageState extends ConsumerState<LinkEmailPage> {
  // フォームのバリデーション管理キー
  final _formKey = GlobalKey<FormState>();
  // 入力値を管理するコントローラー
  final _email    = TextEditingController();
  final _password = TextEditingController();
  // 処理中フラグ（ボタンの二重タップを防ぐ）
  bool _saving = false;

  @override
  void dispose() {
    // 画面が破棄されるときにコントローラーを解放する
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// メールアドレスのバリデーション（入力チェック）
  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'メールは必須です';
    // 正規表現でメール形式を確認
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'メール形式が正しくありません';
  }

  /// パスワードのバリデーション（6文字以上）
  String? _pwValidator(String? v) {
    final s = (v ?? '');
    if (s.length < 6) return 'パスワードは6文字以上';
    return null;
  }

  /// 紐づけ処理を実行する
  Future<void> _link() async {
    if (_saving) return; // 処理中なら無視（二重タップ防止）
    if (!_formKey.currentState!.validate()) return; // バリデーション失敗なら中断

    setState(() => _saving = true); // ボタンを非活性にする

    try {
      // linkEmailProvider = 匿名アカウントにメールを紐づける Provider
      final params = EmailAuthParams(
        email: _email.text.trim(),
        password: _password.text,
      );
      await ref.read(linkEmailProvider(params).future);

      if (!mounted) return;

      // 成功したらスナックバーで通知
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアカウントに紐づけました')),
      );

      // 前の画面に戻る（戻れる場合のみ）
      // Navigator.canPop = ナビゲーションスタックに戻れる画面があるか確認
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 失敗したらエラーメッセージを表示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('失敗: $e')),
      );
    } finally {
      // 成功・失敗どちらでも _saving を false に戻す
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メールログインを有効化')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // メールアドレス入力フィールド
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'メール'),
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              // パスワード入力フィールド（obscureText = 入力文字を●で隠す）
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'パスワード（6文字以上）'),
                obscureText: true,
                validator: _pwValidator,
              ),
              const SizedBox(height: 24),
              // 紐づけ実行ボタン
              // _saving が true のとき null を渡すとボタンが非活性になる
              FilledButton(
                onPressed: _saving ? null : _link,
                child: Text(_saving ? '処理中...' : 'この端末のデータをメールに紐づける'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
