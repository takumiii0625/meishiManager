import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/card_providers.dart';

class CardAddPage extends ConsumerStatefulWidget {
  const CardAddPage({super.key});

  @override
  ConsumerState<CardAddPage> createState() => _CardAddPageState();
}

class _CardAddPageState extends ConsumerState<CardAddPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _company = TextEditingController();
  final _industry = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _industry.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label は必須です';
    return null;
  }

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // 任意
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'メール形式が正しくありません';
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null; // 任意
    final ok = RegExp(r'^[0-9\-\s\(\)]+$').hasMatch(s);
    return ok ? null : '電話番号は数字と記号（- 等）で入力してください';
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final params = AddCardParams(
        name: _name.text.trim(),
        company: _company.text.trim(),
        industry: _industry.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        notes: _notes.text.trim(),
      );

      // await しない（同期完了待ちしない）
      ref.read(addCardProvider(params).future);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('名刺を追加')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: '氏名（必須）'),
                validator: (v) => _required(v, '氏名'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _company,
                decoration: const InputDecoration(labelText: '会社名（必須）'),
                validator: (v) => _required(v, '会社名'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _industry,
                decoration: const InputDecoration(labelText: '業種'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: '電話番号'),
                validator: _phoneValidator,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'メール'),
                validator: _emailValidator,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'メモ'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? '保存中...' : '保存する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
