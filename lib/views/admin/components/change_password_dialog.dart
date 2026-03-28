import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_settings_provider.dart';
import 'admin_theme.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends ConsumerState<ChangePasswordDialog> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(adminSettingsViewModelProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー ──
            Row(
              children: [
                const Expanded(
                  child: Text('パスワードを変更',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textMain)),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AdminColors.textSub),
                  onPressed: () {
                    ref
                        .read(adminSettingsViewModelProvider)
                        .clearMessages();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── エラー ──
            if (vm.errorMessage != null) ...[
              _alertBox(vm.errorMessage!, isError: true),
              const SizedBox(height: 16),
            ],

            // ── 成功 ──
            if (vm.successMessage != null) ...[
              _alertBox(vm.successMessage!, isError: false),
              const SizedBox(height: 16),
            ],

            // ── フォーム ──
            _passField(
              label: '現在のパスワード',
              ctrl: _currentPassCtrl,
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 12),
            _passField(
              label: '新しいパスワード（8文字以上）',
              ctrl: _newPassCtrl,
              obscure: _obscureNew,
              onToggle: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 12),
            _passField(
              label: '新しいパスワード（確認）',
              ctrl: _confirmPassCtrl,
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 24),

            // ── フッター ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () {
                          ref
                              .read(adminSettingsViewModelProvider)
                              .clearMessages();
                          Navigator.pop(context);
                        },
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
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          await ref
                              .read(adminSettingsViewModelProvider)
                              .changePassword(
                                currentPassword: _currentPassCtrl.text,
                                newPassword: _newPassCtrl.text,
                                confirmPassword: _confirmPassCtrl.text,
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('変更する',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertBox(String message, {required bool isError}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isError ? AdminColors.redBg : AdminColors.greenBg,
          border: Border.all(
              color: (isError ? AdminColors.red : AdminColors.green)
                  .withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AdminColors.red : AdminColors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 12,
                      color: isError ? AdminColors.red : AdminColors.green))),
        ]),
      );

  Widget _passField({
    required String label,
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggle,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMid)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            style:
                const TextStyle(fontSize: 13, color: AdminColors.textMain),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AdminColors.textSub,
                ),
                onPressed: onToggle,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AdminColors.primary)),
              filled: true,
              fillColor: AdminColors.bg,
            ),
          ),
        ],
      );
}
