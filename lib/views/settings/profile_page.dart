// ============================================================
// profile_page.dart
// プロフィール詳細・編集画面
//
// 【表示項目】
//   プロフィール画像（アイコン）
//   名前
//   会社名
//   役職
//   電話番号
//   メールアドレス（表示のみ）
//   ログイン方法（Google / メールなど）
//   連携済みSNSバッジ
//   登録日
//
// 【編集可能項目】
//   名前・会社名・役職・電話番号
//
// 【メールアドレス変更】
//   Firebase Auth の再認証が必要なため将来実装予定
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
// auth_theme.dart は auth/components/ フォルダにある
import '../auth/components/auth_theme.dart';

// ── Firestoreからプロフィールを取得するProvider ──────────────
// FutureProvider = 非同期で1回データを取得する
final _profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid.isEmpty) return {};
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return doc.data() ?? {};
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // 編集中かどうかのフラグ
  bool _isEditing = false;
  bool _isSaving  = false;

  // 編集用コントローラー
  final _nameCtrl    = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobCtrl     = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _jobCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// 編集モードに入る（フォームに現在値をセット）
  void _startEditing(Map<String, dynamic> profile) {
    _nameCtrl.text    = profile['name']    as String? ?? '';
    _companyCtrl.text = profile['company'] as String? ?? '';
    _jobCtrl.text     = profile['jobLevel'] as String? ?? '';
    _phoneCtrl.text   = profile['phone']   as String? ?? '';
    setState(() => _isEditing = true);
  }

  /// 保存処理
  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final uid = ref.read(uidProvider);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name':     _nameCtrl.text.trim(),
        'company':  _companyCtrl.text.trim(),
        'jobLevel': _jobCtrl.text.trim(),
        'phone':    _phoneCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Providerをリフレッシュして最新データを取得
      ref.invalidate(_profileProvider);

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを更新しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);
    // Firebase Auth からリアルタイムで取得（メール・連携情報）
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.maybeWhen(data: (u) => u, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            // 編集ボタン
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編集',
              onPressed: () => profileAsync.maybeWhen(
                data: (p) => _startEditing(p),
                orElse: () {},
              ),
            )
          else ...[
            // キャンセルボタン
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('キャンセル',
                  style: TextStyle(color: Colors.white70)),
            ),
            // 保存ボタン
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                _isSaving ? '保存中...' : '保存',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (profile) => _isEditing
            ? _EditView(
                nameCtrl:    _nameCtrl,
                companyCtrl: _companyCtrl,
                jobCtrl:     _jobCtrl,
                phoneCtrl:   _phoneCtrl,
                isSaving:    _isSaving,
                onSave:      _save,
              )
            : _DetailView(profile: profile, user: user),
      ),
    );
  }
}

// ============================================================
// 詳細表示ビュー
// ============================================================
class _DetailView extends StatelessWidget {
  const _DetailView({required this.profile, required this.user});

  final Map<String, dynamic> profile;
  final User? user;

  @override
  Widget build(BuildContext context) {
    // Firestoreのデータ
    final name     = profile['name']     as String? ?? '';
    final company  = profile['company']  as String? ?? '';
    final jobLevel = profile['jobLevel'] as String? ?? '';
    final phone    = profile['phone']    as String? ?? '';
    final email    = user?.email ?? profile['email'] as String? ?? '';
    final createdAt = profile['createdAt'] as Timestamp?;

    // 連携済みプロバイダー
    final providers = user?.providerData.map((p) => p.providerId).toSet() ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── アバター ────────────────────────────────────
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF93C5FD), width: 2),
              ),
              child: Center(
                child: Text(
                  // 名前の頭文字をアバターに表示
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 名前を大きく表示
          Text(
            name.isNotEmpty ? name : '名前未設定',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          if (company.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(company,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF94A3B8))),
          ],
          const SizedBox(height: 24),

          // ── 基本情報セクション ───────────────────────────
          _SectionCard(
            title: '基本情報',
            children: [
              _InfoRow(icon: Icons.person_outline,    label: '名前',     value: name),
              _InfoRow(icon: Icons.business_outlined, label: '会社名',   value: company),
              _InfoRow(icon: Icons.work_outline,      label: '役職',     value: jobLevel),
              _InfoRow(icon: Icons.phone_outlined,    label: '電話番号', value: phone),
            ],
          ),
          const SizedBox(height: 12),

          // ── アカウント情報セクション ─────────────────────
          _SectionCard(
            title: 'アカウント情報',
            children: [
              // メールアドレス（表示のみ）
              _InfoRow(
                icon: Icons.mail_outline,
                label: 'メールアドレス',
                value: email,
                suffix: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('変更不可',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ),
              ),
              // UID（表示のみ）
              _InfoRow(
                icon: Icons.fingerprint,
                label: 'UID',
                value: user?.uid ?? '',
              ),
              // 登録日
              if (createdAt != null)
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: '登録日',
                  value: _formatDate(createdAt.toDate()),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── ログイン方法セクション ───────────────────────
          _SectionCard(
            title: 'ログイン方法',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (providers.contains('google.com'))
                      _ProviderBadge(label: 'Google', color: const Color(0xFFDB4437)),
                    if (providers.contains('facebook.com'))
                      _ProviderBadge(label: 'Facebook', color: const Color(0xFF1877F2)),
                    if (providers.contains('twitter.com'))
                      _ProviderBadge(label: 'X', color: Colors.black),
                    if (providers.contains('password'))
                      _ProviderBadge(label: 'メール', color: const Color(0xFF1E40AF)),
                    if (providers.isEmpty)
                      const Text('未連携',
                          style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// DateTime を「2024年3月28日」形式にフォーマット
  String _formatDate(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日';
  }
}

// ============================================================
// 編集ビュー
// ============================================================
class _EditView extends StatelessWidget {
  const _EditView({
    required this.nameCtrl,
    required this.companyCtrl,
    required this.jobCtrl,
    required this.phoneCtrl,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController nameCtrl;
  final TextEditingController companyCtrl;
  final TextEditingController jobCtrl;
  final TextEditingController phoneCtrl;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 説明バナー ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF1E40AF)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'メールアドレスは変更できません。その他の情報を編集してください。',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── 編集フォーム ────────────────────────────────
          _EditField(ctrl: nameCtrl,    label: '名前',     hint: '山田 太郎',       icon: Icons.person_outline),
          const SizedBox(height: 12),
          _EditField(ctrl: companyCtrl, label: '会社名',   hint: '株式会社〇〇',    icon: Icons.business_outlined),
          const SizedBox(height: 12),
          _EditField(ctrl: jobCtrl,     label: '役職',     hint: '営業部長・代表取締役', icon: Icons.work_outline),
          const SizedBox(height: 12),
          _EditField(
            ctrl: phoneCtrl,
            label: '電話番号',
            hint: '090-1234-5678',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          // ── 保存ボタン ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(isSaving ? '保存中...' : '保存する'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── 共通Widgets ───────────────────────────────────────────

/// セクションカード（タイトル + 子Widget群）
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションタイトル
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }
}

/// 情報行（アイコン・ラベル・値）
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
  });
  final IconData icon;
  final String label;
  final String value;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          // ラベル
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
          // 値
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '未設定',
              style: TextStyle(
                  fontSize: 13,
                  color: value.isNotEmpty
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFCBD5E1)),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

/// SNS連携バッジ
class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// 編集フィールド
class _EditField extends StatelessWidget {
  const _EditField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
  });
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1E40AF))),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}
