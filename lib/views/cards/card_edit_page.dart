// ============================================================
// card_edit_page.dart
// 名刺編集画面
//
// 【概要】
//   card_detail_page の編集ボタンから開く画面。
//   フォームに現在の値を表示し、変更して「保存」すると
//   Firestoreのデータが更新される。
//
// 【フィールド構成】
//   基本情報：氏名・会社名・業種
//   所属情報：部署（優先度高）・役職（優先度低）
//   連絡先：電話・メール・住所
//   その他：都道府県・メモ
// ============================================================

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
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late final TextEditingController _department; // ★ 部署（優先度高）
  late final TextEditingController _jobLevel;   // ★ 役職（優先度低）
  late final TextEditingController _prefecture;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _name       = TextEditingController(text: c.name);
    _company    = TextEditingController(text: c.company);
    _industry   = TextEditingController(text: c.industry);
    _phone      = TextEditingController(text: c.phone);
    _email      = TextEditingController(text: c.email);
    _address    = TextEditingController(text: c.address);
    _notes      = TextEditingController(text: c.notes);
    _department = TextEditingController(text: c.department); // ★ 部署
    _jobLevel   = TextEditingController(text: c.jobLevel);   // ★ 役職
    _prefecture = TextEditingController(text: c.prefecture);
  }

  @override
  void dispose() {
    for (final c in [
      _name, _company, _industry, _phone, _email,
      _address, _notes, _department, _jobLevel, _prefecture,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label は必須です';
    return null;
  }

  String? _emailValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
        ? null
        : 'メール形式が正しくありません';
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^[0-9\-\s\(\)]+$').hasMatch(s)
        ? null
        : '電話番号は数字と記号（- 等）で入力してください';
  }

  Future<void> _update() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(updateCardProvider(UpdateCardParams(
        cardId:        widget.card.id,
        name:          _name.text.trim(),
        company:       _company.text.trim(),
        industry:      _industry.text.trim(),
        phone:         _phone.text.trim(),
        email:         _email.text.trim(),
        address:       _address.text.trim(),
        notes:         _notes.text.trim(),
        department:    _department.text.trim(), // ★ 部署
        jobLevel:      _jobLevel.text.trim(),   // ★ 役職
        prefecture:    _prefecture.text.trim(),
        frontImageUrl: widget.card.frontImageUrl,
        backImageUrl:  widget.card.backImageUrl,
        rawText:       widget.card.rawText,
        tags:          widget.card.tags,
      )).future);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新に失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名刺を編集'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _update,
            child: Text(_saving ? '保存中...' : '保存',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 基本情報 ────────────────────────────────
              _SectionLabel('基本情報'),
              _Field(ctrl: _name,     label: '氏名',   required: true, validator: (v) => _required(v, '氏名')),
              _Field(ctrl: _company,  label: '会社名', required: true, validator: (v) => _required(v, '会社名')),
              _Field(ctrl: _industry, label: '業種',   hint: 'Geminiが自動推定（手動変更可）'),

              // ── 所属情報（部署＞役職の優先度）──────────
              const SizedBox(height: 16),
              _SectionLabel('所属情報'),
              // 部署：役職より優先度高。役職がなくても部署があれば所属がわかる
              _Field(ctrl: _department, label: '部署', hint: '例: 営業部・技術開発部・経営企画室'),
              // 役職：部署がなくても入力可能
              _Field(ctrl: _jobLevel,   label: '役職', hint: '例: 部長・代表取締役・営業担当'),

              // ── 連絡先 ──────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('連絡先'),
              _Field(ctrl: _phone,   label: '電話番号', keyboard: TextInputType.phone,        validator: _phoneValidator),
              _Field(ctrl: _email,   label: 'メール',   keyboard: TextInputType.emailAddress, validator: _emailValidator),
              _Field(ctrl: _address, label: '住所',     maxLines: 2),

              // ── その他 ──────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('その他'),
              _Field(ctrl: _prefecture, label: '都道府県', hint: '例: 東京都'),
              _Field(ctrl: _notes,      label: 'メモ',     maxLines: 4),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _update,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF)),
                child: Text(_saving ? '更新中...' : '更新する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5)),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final bool required;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.required = false,
    this.keyboard,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: required ? '$label（必須）' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
