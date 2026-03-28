import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_settings_provider.dart';
import 'admin_theme.dart';

class LogoutDialog extends ConsumerWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AdminColors.redBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout,
                  size: 24, color: AdminColors.red),
            ),
            const SizedBox(height: 16),
            const Text('ログアウトしますか？',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textMain)),
            const SizedBox(height: 8),
            const Text('管理画面からログアウトします。',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: AdminColors.textSub,
                    height: 1.6)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('キャンセル',
                        style: TextStyle(color: AdminColors.textSub)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(adminSettingsViewModelProvider)
                          .signOut();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushReplacementNamed('/admin/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('ログアウト',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
