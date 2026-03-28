import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import 'components/auth_theme.dart';
import 'components/email_auth_form.dart';
import 'components/social_auth_buttons.dart';

class WebAuthPage extends ConsumerWidget {
  const WebAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateChangesProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    });

    void onSuccess(user) {
      Navigator.of(context).pushReplacementNamed('/home');
    }

    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            margin: const EdgeInsets.all(24),
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 左側：ロゴ・ソーシャルログイン ──
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(48),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF1FD),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ロゴ
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD0D8F8)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4361EE).withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🪪', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Meishi Manager',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AuthColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ビジネス名刺をデジタルで管理',
                            style: TextStyle(
                              fontSize: 13,
                              color: AuthColors.textMid,
                            ),
                          ),
                          const SizedBox(height: 40),
                          SocialAuthButtons(onSuccess: onSuccess),
                        ],
                      ),
                    ),
                  ),

                  // ── 右側：メール/パスワードフォーム ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: EmailAuthForm(onSuccess: onSuccess),
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
