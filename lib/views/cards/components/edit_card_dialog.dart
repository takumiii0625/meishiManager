// ============================================================
// edit_card_dialog.dart
// Web版 名刺編集ダイアログ
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/card_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/card_providers.dart';
import 'cards_theme.dart';

class EditCardDialog extends ConsumerStatefulWidget {
  final CardModel card;
  const EditCardDialog({super.key, required this.card});

  @override
  ConsumerState<EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends ConsumerState<EditCardDialog> {
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _department;
  late final TextEditingController _jobLevel;
  late final TextEditingController _industry;
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
    _department = TextEditingController(text: c.department);
    _jobLevel   = TextEditingController(text: c.jobLevel);
    _industry   = TextEditingController(text: c.industry);
    _phone      = TextEditingController(text: c.phone);
    _email      = TextEditingController(text: c.email);
    _address    = TextEditingController(text: c.address);
    _prefecture = TextEditingController(text: c.prefecture);
    _notes      = TextEditingController(text: c.notes);
  }

  @override
  void dispose() {
    for (final c in [
      _name, _company, _department, _jobLevel, _industry,
      _phone, _email, _address, _prefecture, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _errorMsg = '名前を入力してください');
      return;
    }
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await ref.read(updateCardProvider(UpdateCardParams(
        cardId:        widget.card.id,
        name:          _name.text.trim(),
        company:       _company.text.trim(),
        department:    _department.text.trim(),
        jobLevel:      _jobLevel.text.trim(),
        industry:      _industry.text.trim(),
        phone:         _phone.text.trim(),
        email:         _email.text.trim(),
        address:       _address.text.trim(),
        prefecture:    _prefecture.text.trim(),
        notes:         _notes.text.trim(),
        frontImageUrl: widget.card.frontImageUrl,
        backImageUrl:  widget.card.backImageUrl,
        rawText:       widget.card.rawText,
        tags:          widget.card.tags,
      )).future);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('名刺を更新しました'),
          backgroundColor: CardsColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _errorMsg = 'エラー: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  const Expanded(
                    child: Text('名刺を編集',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CardsColors.textMain)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: CardsColors.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // エラー
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

              // 2カラムレイアウト
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: [
                    _field('名前 *', _name),
                    _field('会社名', _company),
                    _field('部署', _department),
                    _field('役職', _jobLevel),
                    _field('業種', _industry),
                  ])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(children: [
                    _field('電話番号', _phone, keyboardType: TextInputType.phone),
                    _field('メール', _email, keyboardType: TextInputType.emailAddress),
                    _field('都道府県', _prefecture),
                    _field('住所', _address),
                    _field('メモ', _notes, maxLines: 3),
                  ])),
                ],
              ),
              const SizedBox(height: 24),

              // フッター
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CardsColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存する',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CardsColors.textMid)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 13, color: CardsColors.textMain),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CardsColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CardsColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: CardsColors.primary)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      );
}
