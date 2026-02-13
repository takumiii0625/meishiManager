import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';

class LinkEmailPage extends ConsumerStatefulWidget {
  const LinkEmailPage({super.key});

  @override
  ConsumerState<LinkEmailPage> createState() => _LinkEmailPageState();
}

class _LinkEmailPageState extends ConsumerState<LinkEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;

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
    final s = (v ?? '');
    if (s.length < 6) return 'パスワードは6文字以上';
    return null;
  }

  Future<void> _link() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final params = EmailAuthParams(
        email: _email.text.trim(),
        password: _password.text,
      );
      await ref.read(linkEmailProvider(params).future);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアカウントに紐づけました')),
      );

      // ここがポイント：戻れる時だけ戻る
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('失敗: $e')),
      );
    } finally {
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
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'メール'),
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'パスワード（6文字以上）'),
                obscureText: true,
                validator: _pwValidator,
              ),
              const SizedBox(height: 24),
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
