import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/card_providers.dart';
import 'components/auth_theme.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass   = true;
  bool _isLoading     = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'メールアドレスを入力してください');
      return;
    }
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'パスワードを入力してください');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final credential = await ref
          .read(firebaseAuthProvider)
          .signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      final user = credential.user;
      if (user == null) {
        setState(() => _errorMessage = 'ログインに失敗しました');
        return;
      }

      // Firestoreでroleを確認
      final doc = await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .get();

      final role = (doc.data()?['role'] as String?) ?? 'user';

      if (role != 'admin') {
        // 管理者でない場合はサインアウトしてエラー
        await ref.read(firebaseAuthProvider).signOut();
        setState(() => _errorMessage = '管理者アカウントではありません');
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'メールアドレスまたはパスワードが正しくありません';
          break;
        case 'too-many-requests':
          msg = 'ログイン試行回数が多すぎます。しばらくしてからお試しください';
          break;
        default:
          msg = 'エラーが発生しました（${e.code}）';
      }
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(40),
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
                // ── ロゴ・タイトル ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AuthColors.primaryLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Icon(Icons.admin_panel_settings,
                              size: 32, color: AuthColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Meishi Manager',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AuthColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '管理者アカウントでログイン',
                        style: TextStyle(
                            fontSize: 13, color: AuthColors.textSub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── エラーメッセージ ──
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
                                  fontSize: 12, color: AuthColors.red))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── メールアドレス ──
                _label('メールアドレス'),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                      fontSize: 14, color: AuthColors.textMain),
                  decoration: _inputDecoration(
                    hint: 'admin@example.com',
                    prefixIcon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 16),

                // ── パスワード ──
                _label('パスワード'),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePass,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                      fontSize: 14, color: AuthColors.textMain),
                  decoration: _inputDecoration(
                    hint: '8文字以上',
                    prefixIcon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                        color: AuthColors.textSub,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── ログインボタン ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('ログイン',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AuthColors.textMid),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AuthColors.textSub, fontSize: 13),
        prefixIcon: Icon(prefixIcon, size: 18, color: AuthColors.textSub),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AuthColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AuthColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AuthColors.primary)),
        filled: true,
        fillColor: AuthColors.bg,
      );
}
