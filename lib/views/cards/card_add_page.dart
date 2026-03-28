// ============================================================
// card_add_page.dart
// 手動登録画面
//
// 【概要】
//   フォームに入力して名刺を手動で登録する画面。
//   OCRが使えない場合や、名刺がない場合に使う。
//
// 【フィールド構成】
//   基本情報：氏名・会社名・業種
//   所属情報：部署（優先度高）・役職（優先度低）
//   連絡先：電話・メール
//   住所：都道府県・住所詳細
//   メモ
// ============================================================

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

  // 各フィールドのコントローラー
  final _name       = TextEditingController();
  final _company    = TextEditingController();
  final _industry   = TextEditingController();
  final _department = TextEditingController(); // ★ 部署（優先度高）
  final _jobLevel   = TextEditingController(); // ★ 役職（優先度低）
  final _phone      = TextEditingController();
  final _email      = TextEditingController();
  final _address    = TextEditingController();
  final _prefecture = TextEditingController();
  final _notes      = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name, _company, _industry, _department, _jobLevel,
      _phone, _email, _address, _prefecture, _notes,
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

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final params = AddCardParams(
        name:       _name.text.trim(),
        company:    _company.text.trim(),
        industry:   _industry.text.trim(),
        department: _department.text.trim(), // ★ 部署
        jobLevel:   _jobLevel.text.trim(),   // ★ 役職
        phone:      _phone.text.trim(),
        email:      _email.text.trim(),
        address:    _address.text.trim(),
        prefecture: _prefecture.text.trim(),
        notes:      _notes.text.trim(),
      );

      await ref.read(addCardProvider(params).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名刺を登録しました')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存に失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手動で登録'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? '保存中...' : '保存',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 基本情報 ──────────────────────────────────
              _SectionLabel('基本情報'),
              _Field(
                ctrl: _name,
                label: '氏名',
                required: true,
                validator: (v) => _required(v, '氏名'),
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _company,
                label: '会社名',
                required: true,
                validator: (v) => _required(v, '会社名'),
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _industry,
                label: '業種',
                hint: '例: IT・ソフトウェア、製造業',
                action: TextInputAction.next,
              ),

              // ── 所属情報（部署＞役職の優先度）──────────────
              const SizedBox(height: 16),
              _SectionLabel('所属情報'),
              // 部署：役職より優先度高。役職がなくても部署があれば所属がわかる
              _Field(
                ctrl: _department,
                label: '部署',
                hint: '例: 営業部・技術開発部・経営企画室',
                action: TextInputAction.next,
              ),
              // 役職：部署がなくても入力可能
              _Field(
                ctrl: _jobLevel,
                label: '役職',
                hint: '例: 部長・代表取締役・営業担当',
                action: TextInputAction.next,
              ),

              // ── 連絡先 ──────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('連絡先'),
              _Field(
                ctrl: _phone,
                label: '電話番号',
                keyboard: TextInputType.phone,
                validator: _phoneValidator,
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _email,
                label: 'メール',
                keyboard: TextInputType.emailAddress,
                validator: _emailValidator,
                action: TextInputAction.next,
              ),

              // ── 住所 ─────────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('住所'),
              _Field(
                ctrl: _prefecture,
                label: '都道府県',
                hint: '例: 東京都・大阪府・愛知県',
                action: TextInputAction.next,
              ),
              _Field(
                ctrl: _address,
                label: '住所（詳細）',
                hint: '例: 渋谷区渋谷1-2-3',
                maxLines: 2,
              ),

              // ── メモ ─────────────────────────────────────
              const SizedBox(height: 16),
              _SectionLabel('メモ'),
              _Field(
                ctrl: _notes,
                label: 'メモ',
                hint: '自由入力',
                maxLines: 4,
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? '保存中...' : '登録する'),
              ),
              const SizedBox(height: 16),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
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
  final TextInputAction? action;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.required = false,
    this.keyboard,
    this.validator,
    this.maxLines = 1,
    this.action,
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
        textInputAction: action,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
