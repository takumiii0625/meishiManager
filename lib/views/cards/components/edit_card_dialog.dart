// ============================================================
// edit_card_dialog.dart
// Web版 名刺編集ダイアログ
//
// 【フィールド構成】モバイルの card_edit_page.dart と統一
//   基本情報：氏名（必須）・会社名（必須）・業種
//   所属情報：部署・役職
//   連絡先：電話・メール・住所
//   その他：都道府県・メモ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/card_model.dart';
import '../../../providers/card_providers.dart';
import 'cards_theme.dart';

class EditCardDialog extends ConsumerStatefulWidget {
  final CardModel card;
  const EditCardDialog({super.key, required this.card});

  @override
  ConsumerState<EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends ConsumerState<EditCardDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _industry;
  late final TextEditingController _department;
  late final TextEditingController _jobLevel;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _prefecture;
  late final TextEditingController _notes;

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _name       = TextEditingController(text: c.name);
    _company    = TextEditingController(text: c.company);
    _industry   = TextEditingController(text: c.industry);
    _department = TextEditingController(text: c.department);
    _jobLevel   = TextEditingController(text: c.jobLevel);
    _phone      = TextEditingController(text: c.phone);
    _email      = TextEditingController(text: c.email);
    _address    = TextEditingController(text: c.address);
    _prefecture = TextEditingController(text: c.prefecture);
    _notes      = TextEditingController(text: c.notes);
  }

  @override
  void dispose() {
    for (final c in [
      _name, _company, _industry, _department, _jobLevel,
      _phone, _email, _address, _prefecture, _notes,
    ]) { c.dispose(); }
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
        ? null : 'メール形式が正しくありません';
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^[0-9\-\s\(\)]+$').hasMatch(s)
        ? null : '電話番号は数字と記号（- 等）で入力してください';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await ref.read(updateCardProvider(UpdateCardParams(
        cardId:       widget.card.id,
        name:         _name.text.trim(),
        company:      _company.text.trim(),
        industry:     _industry.text.trim(),
        department:   _department.text.trim(),
        jobLevel:     _jobLevel.text.trim(),
        phone:        _phone.text.trim(),
        email:        _email.text.trim(),
        address:      _address.text.trim(),
        prefecture:   _prefecture.text.trim(),
        notes:        _notes.text.trim(),
        frontImageUrl: widget.card.frontImageUrl,
        backImageUrl:  widget.card.backImageUrl,
        rawText:       widget.card.rawText,
        tags:          widget.card.tags,
      )).future);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_name.text.trim()} の名刺を更新しました'),
          backgroundColor: CardsColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _errorMsg = '更新に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ヘッダー ──
                Row(children: [
                  const Expanded(
                    child: Text('名刺を編集',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: CardsColors.textMain)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: CardsColors.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── エラー ──
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: CardsColors.redBg,
                      border: Border.all(color: CardsColors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: CardsColors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!,
                          style: const TextStyle(fontSize: 12, color: CardsColors.red))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 基本情報 ──
                _sectionLabel('基本情報'),
                _field('氏名', _name, required: true,
                    validator: (v) => _required(v, '氏名')),
                _field('会社名', _company, required: true,
                    validator: (v) => _required(v, '会社名')),
                _field('業種', _industry,
                    hint: 'Geminiが自動推定（手動変更可）'),

                // ── 所属情報 ──
                const SizedBox(height: 8),
                _sectionLabel('所属情報'),
                _field('部署', _department,
                    hint: '例: 営業部・技術開発部・経営企画室'),
                _field('役職', _jobLevel,
                    hint: '例: 部長・代表取締役・営業担当'),

                // ── 連絡先 ──
                const SizedBox(height: 8),
                _sectionLabel('連絡先'),
                _field('電話番号', _phone,
                    keyboard: TextInputType.phone,
                    validator: _phoneValidator),
                _field('メール', _email,
                    keyboard: TextInputType.emailAddress,
                    validator: _emailValidator),
                _field('住所', _address, maxLines: 2),

                // ── その他 ──
                const SizedBox(height: 8),
                _sectionLabel('その他'),
                _field('都道府県', _prefecture, hint: '例: 東京都'),
                _field('メモ', _notes, maxLines: 4),

                const SizedBox(height: 24),

                // ── フッター ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CardsColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('キャンセル',
                          style: TextStyle(color: CardsColors.textSub)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CardsColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('更新する',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: Color(0xFF64748B), letterSpacing: 0.5)),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool required = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: CardsColors.textMain),
          decoration: InputDecoration(
            labelText: required ? '$label（必須）' : label,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: CardsColors.textSub),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CardsColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CardsColors.primary)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CardsColors.red)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      );
}
