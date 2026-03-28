import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../../../providers/card_providers.dart';
import 'cards_theme.dart';

class AddCardDialog extends ConsumerStatefulWidget {
  const AddCardDialog({super.key});

  @override
  ConsumerState<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends ConsumerState<AddCardDialog> {
  final _nameCtrl    = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();

  bool _isLoading   = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = '名前を入力してください');
      return;
    }

    // Googleログイン直後はuidProviderの反映が遅れるためfirebaseAuthProviderから直接取得
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    if (uid.isEmpty) {
      setState(() => _errorMsg = 'ログインが確認できません。再ログインしてください');
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      await ref.read(cardRepositoryProvider).addCard(
        uid,
        name:    _nameCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        email:   _emailCtrl.text.trim(),
        phone:   _phoneCtrl.text.trim(),
        notes:   _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_nameCtrl.text.trim()} の名刺を追加しました'),
          backgroundColor: CardsColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _errorMsg = 'エラーが発生しました: $e');
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ヘッダー ──
              Row(
                children: [
                  const Expanded(
                    child: Text('名刺を追加',
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

              // ── エラー ──
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CardsColors.redBg,
                    border: Border.all(
                        color: CardsColors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: CardsColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                fontSize: 12, color: CardsColors.red))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── フォーム ──
              _field('名前 *', _nameCtrl),
              _field('会社名', _companyCtrl),
              _field('メールアドレス', _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              _field('電話番号', _phoneCtrl,
                  keyboardType: TextInputType.phone),
              _field('メモ', _notesCtrl, maxLines: 3),
              const SizedBox(height: 24),

              // ── フッター ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
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
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('追加する',
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
