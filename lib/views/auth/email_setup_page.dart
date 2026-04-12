// ============================================================
// email_setup_page.dart
// メールアドレス登録画面
//
// 【役割】
//   Xでログイン・新規登録した場合、メールアドレスが取得できないため
//   この画面でメールアドレスを入力・保存してもらう。
//
// 【表示条件】
//   auth_gate.dart でログイン後に
//   「Xのみでログイン」かつ「メールアドレスが空」の場合に表示
//
// 【スキップについて】
//   「あとで登録する」を押すと今のセッションはスキップできる
//   ただし flutter run（再起動）するたびに再表示される
//   → メール登録を促す設計（方針A）
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../auth_gate.dart';
import 'components/auth_theme.dart';

class EmailSetupPage extends ConsumerStatefulWidget {
  const EmailSetupPage({super.key});

  @override
  ConsumerState<EmailSetupPage> createState() => _EmailSetupPageState();
}

class _EmailSetupPageState extends ConsumerState<EmailSetupPage> {
  final _emailCtrl  = TextEditingController();
  bool _isSaving    = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  /// メールアドレスのバリデーション
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) return 'メールアドレスを入力してください';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'メールアドレスの形式が正しくありません';
    }
    return null;
  }

  /// メールアドレスを保存してホームへ
  Future<void> _save() async {
    final err = _validateEmail(_emailCtrl.text);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }

    setState(() {
      _isSaving     = true;
      _errorMessage = null;
    });

    try {
      final uid   = ref.read(uidProvider);
      final email = _emailCtrl.text.trim();

      // Firestore にメールアドレスを保存
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'email':     email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // emailSetupDoneProvider を true にすると
      // auth_gate.dart が自動で HomeShell に切り替わる
      ref.read(emailSetupDoneProvider.notifier).state = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'メールアドレスの保存に失敗しました';
        _isSaving     = false;
      });
    }
  }

  /// スキップして今のセッションはホームへ
  /// 次回起動時はまた EmailSetupPage が表示される
  void _skip() {
    ref.read(emailSetupDoneProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AuthColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── アイコン ──────────────────────────────
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AuthColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(Icons.mail_outline,
                            size: 32, color: AuthColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── タイトル ─────────────────────────────
                  const Center(
                    child: Text(
                      'メールアドレスを登録',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AuthColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Xではメールアドレスを取得できないため\n登録をお願いします',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AuthColors.textSub,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── エラーメッセージ ──────────────────────
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AuthColors.redBg,
                        border: Border.all(
                            color: AuthColors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AuthColors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  fontSize: 12, color: AuthColors.red)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── メールアドレス入力 ────────────────────
                  const Text(
                    'メールアドレス',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AuthColors.textMid),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    onSubmitted: (_) => _save(),
                    style: const TextStyle(
                        fontSize: 14, color: AuthColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: const TextStyle(
                          color: AuthColors.textSub, fontSize: 13),
                      prefixIcon: const Icon(Icons.mail_outline,
                          size: 18, color: AuthColors.textSub),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AuthColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AuthColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AuthColors.primary)),
                      filled: true,
                      fillColor: AuthColors.bg,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 登録ボタン ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('登録する',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── スキップボタン ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSaving ? null : _skip,
                      child: const Text(
                        'あとで登録する',
                        style: TextStyle(
                            color: AuthColors.textSub, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
