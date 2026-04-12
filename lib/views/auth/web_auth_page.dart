// ============================================================
// web_auth_page.dart
// ログイン画面
//
// 【レイアウト自動切り替え】
//   Web（kIsWeb = true）  → 横2カラム（左：ロゴ+SNS / 右：メールフォーム）
//   スマホ（kIsWeb = false）→ 縦1カラム（ロゴ → SNS → メールフォーム）
// ============================================================

import 'package:flutter/foundation.dart'; // kIsWeb
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
    // ログイン成功したら /home へ遷移
    // ログイン状態の変化を監視して画面遷移する
    // ただし「すでにログイン済みの状態での変化」には反応しない
    // （SNS連携時の authStateChanges 発火でクラッシュするのを防ぐ）
    final isAlreadyLoggedIn = ref.read(authStateChangesProvider).maybeWhen(
      data: (u) => u != null && !u.isAnonymous,
      orElse: () => false,
    );

    if (!isAlreadyLoggedIn) {
      ref.listen(authStateChangesProvider, (_, next) {
        next.whenData((user) {
          if (user != null && !user.isAnonymous && context.mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      });
    }

    void onSuccess(user) {
      if (!context.mounted) return;
      // キーボードが表示されていたら閉じる
      FocusScope.of(context).unfocus();
      Navigator.of(context).pushReplacementNamed('/home');
    }

    // kIsWeb = true → Web用レイアウト
    // kIsWeb = false → スマホ用レイアウト
    return kIsWeb
        ? _WebLayout(onSuccess: onSuccess)
        : _MobileLayout(onSuccess: onSuccess);
  }
}

// ============================================================
// Web用レイアウト（横2カラム）
// 変更なし・元のデザインをそのまま維持
// ============================================================
class _WebLayout extends StatelessWidget {
  const _WebLayout({required this.onSuccess});
  final void Function(dynamic user) onSuccess;

  @override
  Widget build(BuildContext context) {
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
                          _LogoWidget(),
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

// ============================================================
// スマホ用レイアウト（縦1カラム）
//
// 【構成】
//   ロゴ
//   ↓
//   Googleでログイン
//   Facebookでログイン
//   Xでログイン
//   ↓
//   ── または ──
//   ↓
//   メール/パスワードフォーム
// ============================================================
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.onSuccess});
  final void Function(dynamic user) onSuccess;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── ロゴ ──────────────────────────────────────
              _LogoWidget(),
              const SizedBox(height: 40),

              // ── SNSログインボタン ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuthColors.border),
                ),
                child: SocialAuthButtons(onSuccess: onSuccess),
              ),
              const SizedBox(height: 16),

              // ── 区切り線「または」────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AuthColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'または',
                      style: TextStyle(
                        fontSize: 12,
                        color: AuthColors.textSub,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AuthColors.border)),
                ],
              ),
              const SizedBox(height: 16),

              // ── メール/パスワードフォーム ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuthColors.border),
                ),
                child: EmailAuthForm(onSuccess: onSuccess),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ロゴ Widget（Web・スマホ共通）
// ============================================================
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        const SizedBox(height: 16),
        const Text(
          'Meishi Manager',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AuthColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'ビジネス名刺をデジタルで管理',
          style: TextStyle(
            fontSize: 13,
            color: AuthColors.textMid,
          ),
        ),
      ],
    );
  }
}
