import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/web_auth_provider.dart';
import 'auth_theme.dart';

/// Google・Facebook・Xのログインボタンをまとめたウィジェット
class SocialAuthButtons extends ConsumerWidget {
  const SocialAuthButtons({super.key, required this.onSuccess});

  final void Function(User user) onSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(webAuthViewModelProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 説明文：初めての方も既存ユーザーも同じボタンでOKと伝える
        const Text(
          'ソーシャルアカウントでログイン',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1F36),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          '初めての方は自動で登録されます',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF9396A5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _socialButton(
          onPressed: vm.isLoading ? null : () async {
            FocusScope.of(context).unfocus(); // キーボードを閉じる
            final user = await ref.read(webAuthViewModelProvider).signInWithGoogle();
            if (user != null) onSuccess(user);
          },
          icon: _googleIcon(),
          label: 'Googleでログイン',
        ),
        const SizedBox(height: 12),
        _socialButton(
          onPressed: vm.isLoading ? null : () async {
            FocusScope.of(context).unfocus(); // キーボードを閉じる
            final user = await ref.read(webAuthViewModelProvider).signInWithFacebook();
            if (user != null) onSuccess(user);
          },
          icon: _facebookIcon(),
          label: 'Facebookでログイン',
        ),
        const SizedBox(height: 12),
        _socialButton(
          onPressed: vm.isLoading ? null : () async {
            FocusScope.of(context).unfocus(); // キーボードを閉じる
            final user = await ref.read(webAuthViewModelProvider).signInWithTwitter();
            if (user != null) onSuccess(user);
          },
          icon: _twitterIcon(),
          label: 'Xでログイン',
        ),
      ],
    );
  }

  Widget _socialButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE8EAF0)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _googleIcon() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AuthColors.border),
        ),
        child: const Center(
          child: Text('G',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AuthColors.googleRed,
              )),
        ),
      );

  Widget _facebookIcon() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF1877F2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text('f',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              )),
        ),
      );

  Widget _twitterIcon() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text('𝕏',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              )),
        ),
      );
}
