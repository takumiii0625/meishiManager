import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_providers.dart';
import 'admin_theme.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyCtrl  = TextEditingController();

  String _selectedRole  = 'user';
  bool _isLoading       = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // バリデーション
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = '名前を入力してください');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'メールアドレスを入力してください');
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      setState(() => _errorMessage = 'パスワードは8文字以上で入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(adminUsersViewModelProvider).createUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        company: _companyCtrl.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_nameCtrl.text.trim()} を追加しました'),
          backgroundColor: AdminColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } on Exception catch (e) {
      final err = e.toString();
      String msg = 'エラーが発生しました';
      if (err.contains('email-already-in-use')) {
        msg = 'このメールアドレスはすでに使用されています';
      } else if (err.contains('invalid-email')) {
        msg = 'メールアドレスの形式が正しくありません';
      } else if (err.contains('weak-password')) {
        msg = 'パスワードが弱すぎます。8文字以上にしてください';
      }
      setState(() => _errorMessage = msg);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー ──
            Row(
              children: [
                const Expanded(
                  child: Text('ユーザー追加',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textMain)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminColors.textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '※ 初期パスワードはユーザーに別途お知らせください',
              style: TextStyle(fontSize: 11, color: AdminColors.textSub),
            ),
            const SizedBox(height: 20),

            // ── エラーメッセージ ──
            if (_errorMessage != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AdminColors.redBg,
                  border:
                      Border.all(color: AdminColors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AdminColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              fontSize: 12, color: AdminColors.red)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── フォーム ──
            AdminFormField('名前', _nameCtrl),
            AdminFormField('メールアドレス', _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            AdminFormField('会社名（任意）', _companyCtrl),

            // ── パスワード（表示切替付き）──
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('初期パスワード',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textMid)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                        fontSize: 13, color: AdminColors.textMain),
                    decoration: InputDecoration(
                      hintText: '8文字以上',
                      hintStyle: const TextStyle(
                          color: AdminColors.textSub, fontSize: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                          color: AdminColors.textSub,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AdminColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AdminColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AdminColors.primary)),
                      filled: true,
                      fillColor: AdminColors.bg,
                    ),
                  ),
                ],
              ),
            ),

            // ── 権限選択 ──
            AdminDropdownField(
              label: '権限',
              value: _selectedRole,
              options: const {'user': 'ユーザー', 'admin': '管理者'},
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 24),

            // ── フッター ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AdminColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('キャンセル',
                      style: TextStyle(color: AdminColors.textSub)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('追加する',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
