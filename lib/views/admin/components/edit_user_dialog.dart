import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/admin_providers.dart';
import 'admin_theme.dart';

class EditUserDialog extends ConsumerStatefulWidget {
  const EditUserDialog({super.key, required this.doc});

  final DocumentSnapshot doc;

  @override
  ConsumerState<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<EditUserDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _companyCtrl;
  late String _selectedStatus;
  late String _selectedRole;
  late String _oldStatus;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _nameCtrl       = TextEditingController(text: data['name']    ?? '');
    _emailCtrl      = TextEditingController(text: data['email']   ?? '');
    _companyCtrl    = TextEditingController(text: data['company'] ?? '');
    _selectedStatus = data['status'] ?? 'active';
    _selectedRole   = data['role']   ?? 'user';
    _oldStatus      = _selectedStatus;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(adminUsersViewModelProvider).updateUser(
      userId:    widget.doc.id,
      name:      _nameCtrl.text,
      email:     _emailCtrl.text,
      company:   _companyCtrl.text,
      status:    _selectedStatus,
      role:      _selectedRole,
      oldStatus: _oldStatus,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー ──
            Row(
              children: [
                const Expanded(
                  child: Text('ユーザー編集',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textMain)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminColors.textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── フォーム ──
            AdminFormField('名前', _nameCtrl),
            AdminFormField('メールアドレス', _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            AdminFormField('会社名', _companyCtrl),
            AdminDropdownField(
              label: 'ステータス',
              value: _selectedStatus,
              options: const {'active': '有効', 'suspended': '停止中'},
              onChanged: (v) => setState(() => _selectedStatus = v!),
            ),
            AdminDropdownField(
              label: '権限',
              value: _selectedRole,
              options: const {'user': 'ユーザー', 'admin': '管理者'},
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 24),

            // ── フッター ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('保存する',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
