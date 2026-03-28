import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/web_auth_provider.dart';
import 'auth_theme.dart';

/// メール/パスワードフォーム + Googleログインボタン
class EmailAuthForm extends ConsumerStatefulWidget {
  const EmailAuthForm({super.key, required this.onSuccess});

  /// ログイン/登録成功時のコールバック
  final void Function(User user) onSuccess;

  @override
  ConsumerState<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends ConsumerState<EmailAuthForm> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _companyCtrl  = TextEditingController();
  bool _obscurePass   = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  // ── メール認証 ──
  Future<void> _submitEmail() async {
    final vm = ref.read(webAuthViewModelProvider);

    // 新規登録時は名前バリデーション
    if (!vm.isLogin && _nameCtrl.text.trim().isEmpty) {
      vm
        ..errorMessage = '名前を入力してください'
        ..notifyListeners();
      return;
    }

    final emailErr = vm.validateEmail(_emailCtrl.text);
    if (emailErr != null) {
      vm
        ..errorMessage = emailErr
        ..notifyListeners();
      return;
    }
    final passErr = vm.validatePassword(_passwordCtrl.text);
    if (passErr != null) {
      vm
        ..errorMessage = passErr
        ..notifyListeners();
      return;
    }

    User? user;
    if (vm.isLogin) {
      user = await vm.signInWithEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else {
      user = await vm.signUpWithEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
      );
    }

    if (user != null && mounted) widget.onSuccess(user);
  }

  // ── パスワードリセットダイアログ ──
  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isSending = false;
          bool isSent = false;
          String? errorMsg;

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              child: StatefulBuilder(
                builder: (context, setInnerState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('パスワードをリセット',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AuthColors.textMain)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AuthColors.textSub),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '登録済みのメールアドレスを入力してください。\nパスワードリセット用のリンクをお送りします。',
                      style: TextStyle(
                          fontSize: 13,
                          color: AuthColors.textSub,
                          height: 1.6),
                    ),
                    const SizedBox(height: 20),

                    if (isSent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F9EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF1A8C4E)
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: Color(0xFF1A8C4E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${resetEmailCtrl.text} にリセットメールを送信しました',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1A8C4E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuthColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('閉じる',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ] else ...[
                      if (errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AuthColors.redBg,
                            border: Border.all(
                                color:
                                    AuthColors.red.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: AuthColors.red),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(errorMsg!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AuthColors.red))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _label('メールアドレス'),
                      const SizedBox(height: 6),
                      _textField(
                        controller: resetEmailCtrl,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                        onSubmitted: () async {
                          if (resetEmailCtrl.text.trim().isEmpty) {
                            setInnerState(() =>
                                errorMsg = 'メールアドレスを入力してください');
                            return;
                          }
                          setInnerState(() => isSending = true);
                          try {
                            await ref
                                .read(webAuthViewModelProvider)
                                .sendPasswordResetEmail(
                                    resetEmailCtrl.text.trim());
                            setInnerState(() {
                              isSent = true;
                              isSending = false;
                            });
                          } catch (e) {
                            setInnerState(() {
                              errorMsg = 'メールの送信に失敗しました';
                              isSending = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AuthColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text('キャンセル',
                                style: TextStyle(
                                    color: AuthColors.textSub)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    if (resetEmailCtrl.text
                                        .trim()
                                        .isEmpty) {
                                      setInnerState(() => errorMsg =
                                          'メールアドレスを入力してください');
                                      return;
                                    }
                                    setInnerState(
                                        () => isSending = true);
                                    try {
                                      await ref
                                          .read(
                                              webAuthViewModelProvider)
                                          .sendPasswordResetEmail(
                                              resetEmailCtrl.text
                                                  .trim());
                                      setInnerState(() {
                                        isSent = true;
                                        isSending = false;
                                      });
                                    } catch (e) {
                                      setInnerState(() {
                                        errorMsg = 'メールの送信に失敗しました';
                                        isSending = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AuthColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              elevation: 0,
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Text('送信する',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Twitterログイン ──
  Future<void> _submitTwitter() async {
    final vm = ref.read(webAuthViewModelProvider);
    final user = await vm.signInWithTwitter();
    if (user != null && mounted) widget.onSuccess(user);
  }

  // ── Facebookログイン ──
  Future<void> _submitFacebook() async {
    final vm = ref.read(webAuthViewModelProvider);
    final user = await vm.signInWithFacebook();
    if (user != null && mounted) widget.onSuccess(user);
  }

  // ── Googleログイン ──
  Future<void> _submitGoogle() async {
    final vm = ref.read(webAuthViewModelProvider);
    final user = await vm.signInWithGoogle();
    if (user != null && mounted) widget.onSuccess(user);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(webAuthViewModelProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── タイトル ──
        Text(
          vm.isLogin ? 'ログイン' : '新規登録',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AuthColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          vm.isLogin ? 'メールアドレスでログインする' : 'メールアドレスで新規登録する',
          style: const TextStyle(fontSize: 13, color: AuthColors.textSub),
        ),
        const SizedBox(height: 24),

        // ── エラーメッセージ ──
        if (vm.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AuthColors.redBg,
              border: Border.all(color: AuthColors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AuthColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(vm.errorMessage!,
                      style: const TextStyle(
                          fontSize: 12, color: AuthColors.red)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── メールアドレス ──
        _label('メールアドレス *'),
        const SizedBox(height: 6),
        _textField(
          controller: _emailCtrl,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline,
          onSubmitted: _submitEmail,
        ),
        const SizedBox(height: 16),

        // ── パスワード ──
        _label('パスワード *'),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(fontSize: 14, color: AuthColors.textMain),
          onSubmitted: (_) => _submitEmail(),
          decoration: InputDecoration(
            hintText: '8文字以上',
            hintStyle: const TextStyle(color: AuthColors.textSub, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline,
                size: 18, color: AuthColors.textSub),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AuthColors.textSub,
              ),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
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
          ),
        ),
        const SizedBox(height: 28),

        // ── 新規登録時のみ：名前・会社名 ──
        if (!vm.isLogin) ...[
          _label('名前 *'),
          const SizedBox(height: 6),
          _textField(
            controller: _nameCtrl,
            hint: '山田 太郎',
            prefixIcon: Icons.person_outline,
            onSubmitted: _submitEmail,
          ),
          const SizedBox(height: 16),
          _label('会社名（任意）'),
          const SizedBox(height: 6),
          _textField(
            controller: _companyCtrl,
            hint: '株式会社〇〇',
            prefixIcon: Icons.business_outlined,
            onSubmitted: _submitEmail,
          ),
          const SizedBox(height: 28),
        ],

        // ── ログイン時のみ：パスワードを忘れた方はこちら ──
        if (vm.isLogin) ...[
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showForgotPasswordDialog(context),
              child: const Text(
                'パスワードをお忘れの方はこちら',
                style: TextStyle(
                  fontSize: 12,
                  color: AuthColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── ログイン/登録ボタン ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: vm.isLoading ? null : _submitEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: vm.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    vm.isLogin ? 'ログイン' : '新規登録',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // ── ログイン/新規登録 切り替え ──
        Center(
          child: GestureDetector(
            onTap: vm.isLoading ? null : vm.toggleMode,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: vm.isLogin
                        ? 'アカウントをお持ちでない方は '
                        : 'すでにアカウントをお持ちの方は ',
                    style: const TextStyle(color: AuthColors.textSub),
                  ),
                  TextSpan(
                    text: vm.isLogin ? '新規登録' : 'ログイン',
                    style: const TextStyle(
                      color: AuthColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AuthColors.textMid),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    required IconData prefixIcon,
    required VoidCallback onSubmitted,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AuthColors.textMain),
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AuthColors.textSub, fontSize: 13),
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
        ),
      );
}
