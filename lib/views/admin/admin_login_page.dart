import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ログイン画面専用カラー定数（admin_users_pageと統一）
class _C {
  static const primary     = Color(0xFF4361EE);
  static const primaryLight = Color(0xFFEEF1FD);
  static const bg          = Color(0xFFF4F6FB);
  static const border      = Color(0xFFE8EAF0);
  static const textMain    = Color(0xFF1A1F36);
  static const textSub     = Color(0xFF9396A5);
  static const textMid     = Color(0xFF6B6F82);
  static const red         = Color(0xFFE53E3E);
  static const redBg       = Color(0xFFFFF5F5);
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading           = false;
  bool _obscurePassword     = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // バリデーション
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'メールアドレスを入力してください');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'パスワードを入力してください');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'ログインに失敗しました';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'メールアドレスまたはパスワードが正しくありません';
      } else if (e.code == 'invalid-email') {
        msg = 'メールアドレスの形式が正しくありません';
      } else if (e.code == 'too-many-requests') {
        msg = 'ログイン試行回数が多すぎます。しばらくしてからお試しください';
      }
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _C.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🪪', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CardAdmin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '管理者アカウントでログイン',
                        style: TextStyle(fontSize: 13, color: _C.textSub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── エラーメッセージ ──
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.redBg,
                      border: Border.all(color: _C.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: _C.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: _C.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── メールアドレス ──
                const Text(
                  'メールアドレス',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMid),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: _C.textMain),
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    hintText: 'admin@example.com',
                    hintStyle: const TextStyle(color: _C.textSub, fontSize: 13),
                    prefixIcon: const Icon(Icons.mail_outline, size: 18, color: _C.textSub),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _C.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _C.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _C.primary)),
                    filled: true,
                    fillColor: _C.bg,
                  ),
                ),
                const SizedBox(height: 16),

                // ── パスワード ──
                const Text(
                  'パスワード',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMid),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, color: _C.textMain),
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: _C.textSub, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, size: 18, color: _C.textSub),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: _C.textSub,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _C.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _C.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _C.primary)),
                    filled: true,
                    fillColor: _C.bg,
                  ),
                ),
                const SizedBox(height: 28),

                // ── ログインボタン ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'ログイン',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}