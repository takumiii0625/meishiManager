import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_model.dart';
import '../../providers/card_providers.dart';

class CardEditPage extends ConsumerStatefulWidget {
  const CardEditPage({super.key, required this.card});

  final CardModel card;

  @override
  ConsumerState<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends ConsumerState<CardEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _industry;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _name = TextEditingController(text: c.name);
    _company = TextEditingController(text: c.company);
    _industry = TextEditingController(text: c.industry);
    _phone = TextEditingController(text: c.phone);
    _email = TextEditingController(text: c.email);
    _notes = TextEditingController(text: c.notes);
  }

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
    if (s.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'メール形式が正しくありません';
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final ok = RegExp(r'^[0-9\-\s\(\)]+$').hasMatch(s);
    return ok ? null : '電話番号は数字と記号（- 等）で入力してください';
  }

  Future<void> _update() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final uid = ref.read(uidProvider);
      final repo = ref.read(cardRepositoryProvider);

      // await しない：同期完了を待たずにキューに投げる
      repo.updateCard(
        uid,
        widget.card.id,
        name: _name.text.trim(),
        company: _company.text.trim(),
        industry: _industry.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        notes: _notes.text.trim(),
        imageUrl: widget.card.imageUrl,
        rawText: widget.card.rawText,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // 詳細へ戻る（一覧はstreamで更新）
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名刺を編集'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _update,
            child: Text(_saving ? '更新中...' : '保存'),
          ),
        ],
      ),
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _company,
                decoration: const InputDecoration(labelText: '会社名（必須）'),
                validator: (v) => _required(v, '会社名'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _industry,
                decoration: const InputDecoration(labelText: '業種'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: '電話番号'),
                validator: _phoneValidator,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'メール'),
                validator: _emailValidator,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'メモ'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _update,
                child: Text(_saving ? '更新中...' : '更新する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
