import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_settings_provider.dart';
import 'components/admin_theme.dart';
import 'components/change_password_dialog.dart';
import 'components/logout_dialog.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm   = ref.watch(adminSettingsViewModelProvider);
    final user = vm.currentUser;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('設定',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textMain,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('アカウントと管理設定',
                style: TextStyle(fontSize: 13, color: AdminColors.textSub)),
            const SizedBox(height: 32),

            // ── アカウント情報 ──
            _sectionTitle('アカウント情報'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.mail_outline,
                    label: 'メールアドレス',
                    value: user?.email ?? '—',
                  ),
                  const Divider(height: 1, color: AdminColors.border),
                  _infoRow(
                    icon: Icons.badge_outlined,
                    label: 'UID',
                    value: user?.uid ?? '—',
                    isMonospace: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── アカウント操作 ──
            _sectionTitle('アカウント操作'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _actionRow(
                    icon: Icons.lock_outline,
                    label: 'パスワードを変更',
                    color: AdminColors.primary,
                    bg: AdminColors.primaryLight,
                    onTap: () =>
                        _showChangePasswordDialog(context, ref),
                  ),
                  const Divider(height: 1, color: AdminColors.border),
                  _actionRow(
                    icon: Icons.logout,
                    label: 'ログアウト',
                    color: AdminColors.red,
                    bg: AdminColors.redBg,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── セクションタイトル ──
  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AdminColors.textMid,
            letterSpacing: 0.5),
      );

  // ── カード ──
  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: child,
      );

  // ── 情報行 ──
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) =>
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AdminColors.textMid),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AdminColors.textMid)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  color: AdminColors.textMain,
                  fontFamily: isMonospace ? 'monospace' : null,
                )),
          ],
        ),
      );

  // ── アクション行 ──
  Widget _actionRow({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 18, color: color),
            ],
          ),
        ),
      );


  // ── パスワード変更ダイアログ ──
  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  // ── ログアウト確認ダイアログ ──
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
  }
}
