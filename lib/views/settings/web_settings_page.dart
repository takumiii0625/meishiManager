// ============================================================
// web_settings_page.dart
// Web版 設定画面
//
// 【画面構成】（左サイドバー + 右コンテンツ）
//   サイドバー:
//     - プロフィール
//     - アカウント連携
//     - パスワード変更
//     - ログアウト
//   コンテンツ:
//     選択したセクションの内容を右側に表示
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/web_auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/mail_app_service.dart';
import '../cards/components/cards_theme.dart';

// ── Firestoreからプロフィールを取得するProvider ──────────────
final _webProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid.isEmpty) return {};
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return doc.data() ?? {};
});

// ── 現在のセクション（サイドバー選択）────────────────────────
enum _Section { profile, sns, mail, password, danger }

class WebSettingsPage extends ConsumerStatefulWidget {
  const WebSettingsPage({super.key});

  @override
  ConsumerState<WebSettingsPage> createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends ConsumerState<WebSettingsPage> {
  _Section _section = _Section.profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CardsColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: CardsColors.border),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 左サイドバー ─────────────────────────────
                _buildSidebar(),
                const VerticalDivider(width: 1, color: CardsColors.border),
                // ── 右コンテンツ ─────────────────────────────
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ヘッダー ────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          // 戻るボタン
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CardsColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CardsColors.border),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18, color: CardsColors.textMid),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CardsColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Text('⚙️', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          const Text(
            '設定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CardsColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── サイドバー ──────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarItem(
            icon: Icons.person_outline,
            label: 'プロフィール',
            selected: _section == _Section.profile,
            onTap: () => setState(() => _section = _Section.profile),
          ),
          const SizedBox(height: 4),
          _SidebarItem(
            icon: Icons.link,
            label: 'アカウント連携',
            selected: _section == _Section.sns,
            onTap: () => setState(() => _section = _Section.sns),
          ),
          const SizedBox(height: 4),
          _SidebarItem(
            icon: Icons.mail_outline,
            label: 'メールアプリ',
            selected: _section == _Section.mail,
            onTap: () => setState(() => _section = _Section.mail),
          ),
          const SizedBox(height: 4),
          _SidebarItem(
            icon: Icons.lock_outline,
            label: 'パスワード変更',
            selected: _section == _Section.password,
            onTap: () => setState(() => _section = _Section.password),
          ),
          const Spacer(),
          // 危険な操作は一番下に分離
          const Divider(color: CardsColors.border),
          const SizedBox(height: 4),
          _SidebarItem(
            icon: Icons.logout,
            label: 'ログアウト',
            selected: _section == _Section.danger,
            color: CardsColors.red,
            onTap: () => setState(() => _section = _Section.danger),
          ),
        ],
      ),
    );
  }

  // ── コンテンツ（セクション別） ───────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: switch (_section) {
        _Section.profile  => _ProfileSection(),
        _Section.sns      => _SnsSection(),
        _Section.mail     => const _MailSection(),
        _Section.password => const _PasswordSection(),
        _Section.danger   => const _DangerSection(),
      },
    );
  }
}

// ============================================================
// サイドバーアイテム
// ============================================================
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? CardsColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? activeColor : CardsColors.textMid),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? activeColor : CardsColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// セクション共通: タイトルヘッダー
// ============================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CardsColors.textMain)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: CardsColors.textSub)),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================
// プロフィールセクション
// ============================================================
class _ProfileSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  bool _isEditing = false;
  bool _isSaving  = false;

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

  void _startEditing(Map<String, dynamic> profile) {
    _nameCtrl.text    = profile['name']     as String? ?? '';
    _companyCtrl.text = profile['company']  as String? ?? '';
    _jobCtrl.text     = profile['jobLevel'] as String? ?? '';
    _phoneCtrl.text   = profile['phone']    as String? ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final uid = ref.read(uidProvider);
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'name':      _nameCtrl.text.trim(),
          'company':   _companyCtrl.text.trim(),
          'jobLevel':  _jobCtrl.text.trim(),
          'phone':     _phoneCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // 既存フィールドを消さずに上書き
      );
      ref.invalidate(_webProfileProvider);
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ プロフィールを更新しました')),
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
    final profileAsync = ref.watch(_webProfileProvider);
    final userAsync    = ref.watch(authStateChangesProvider);
    final user = userAsync.maybeWhen(data: (u) => u, orElse: () => null);

    return profileAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('エラー: $e'),
      data: (profile) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'プロフィール',
            subtitle: '名前・会社名・役職など基本情報を管理します',
          ),
          _buildCard(
            child: Column(
              children: [
                // ── アバター＋名前 ────────────────────────
                Row(
                  children: [
                    _Avatar(
                        name: profile['name'] as String? ?? '',
                        email: user?.email ?? ''),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (profile['name'] as String?)?.isNotEmpty == true
                                ? profile['name'] as String
                                : '名前未設定',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: CardsColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'メール未設定',
                            style: const TextStyle(
                                fontSize: 13, color: CardsColors.textSub),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing)
                      ElevatedButton.icon(
                        onPressed: () => _startEditing(profile),
                        icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                        label: const Text('編集',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CardsColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 32, color: CardsColors.border),
                // ── 表示 or 編集フォーム ───────────────────
                if (!_isEditing)
                  ..._buildInfoRows(profile, user)
                else
                  _buildEditForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoRows(Map<String, dynamic> p, User? user) {
    final items = [
      (Icons.person_outline,    '名前',      p['name']     as String? ?? ''),
      (Icons.business_outlined, '会社名',    p['company']  as String? ?? ''),
      (Icons.work_outline,      '役職',      p['jobLevel'] as String? ?? ''),
      (Icons.phone_outlined,    '電話番号',  p['phone']    as String? ?? ''),
      (Icons.mail_outline,      'メール',    user?.email   ?? ''),
    ];
    return items
        .map((item) => _InfoRow(icon: item.$1, label: item.$2, value: item.$3))
        .toList();
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WebEditField(ctrl: _nameCtrl,    label: '名前',    hint: '山田 太郎',       icon: Icons.person_outline),
        const SizedBox(height: 16),
        _WebEditField(ctrl: _companyCtrl, label: '会社名',  hint: '株式会社〇〇',    icon: Icons.business_outlined),
        const SizedBox(height: 16),
        _WebEditField(ctrl: _jobCtrl,     label: '役職',    hint: '営業部長',         icon: Icons.work_outline),
        const SizedBox(height: 16),
        _WebEditField(
          ctrl: _phoneCtrl, label: '電話番号', hint: '090-1234-5678',
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CardsColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('キャンセル',
                  style: TextStyle(color: CardsColors.textMid)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 16, color: Colors.white),
              label: Text(_isSaving ? '保存中...' : '保存する',
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: CardsColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// SNS連携セクション
// ============================================================
class _SnsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.maybeWhen(data: (u) => u, orElse: () => null);
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? {};

    final isGoogle   = providers.contains('google.com');
    final isFacebook = providers.contains('facebook.com');
    final isTwitter  = providers.contains('twitter.com');
    final isEmail    = providers.contains('password');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'アカウント連携',
          subtitle: '外部サービスのアカウントと連携すると、複数の方法でログインできます',
        ),
        _buildCard(
          child: Column(
            children: [
              _SnsRow(
                icon: _GoogleIcon(),
                name: 'Google',
                description: 'Googleアカウントでログインできるようにします',
                isLinked: isGoogle,
                onLink: isGoogle
                    ? null
                    : () => _linkGoogle(context, ref),
              ),
              const Divider(height: 1, color: CardsColors.border),
              _SnsRow(
                icon: _FacebookIcon(),
                name: 'Facebook',
                description: 'Facebookアカウントでログインできるようにします',
                isLinked: isFacebook,
                onLink: isFacebook
                    ? null
                    : () => _linkFacebook(context, ref),
              ),
              const Divider(height: 1, color: CardsColors.border),
              _SnsRow(
                icon: _XIcon(),
                name: 'X（旧Twitter）',
                description: 'Xアカウントでログインできるようにします',
                isLinked: isTwitter,
                onLink: isTwitter
                    ? null
                    : () => _linkTwitter(context, ref),
              ),
              const Divider(height: 1, color: CardsColors.border),
              _SnsRow(
                icon: const Icon(Icons.mail_outline,
                    size: 22, color: CardsColors.primary),
                name: 'メール/パスワード',
                description: 'メールとパスワードでログインできるようにします',
                isLinked: isEmail,
                onLink: null, // メール連携は別途パスワードセクションから
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) =>
      _WebSettingsCard(child: child);

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(webAuthViewModelProvider).linkWithGoogle();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Googleアカウントと連携しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google連携に失敗: $e')));
    }
  }

  Future<void> _linkFacebook(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(webAuthViewModelProvider).linkWithFacebook();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Facebookアカウントと連携しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Facebook連携に失敗: $e')));
    }
  }

  Future<void> _linkTwitter(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(webAuthViewModelProvider).linkWithTwitter();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Xアカウントと連携しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('X連携に失敗: $e')));
    }
  }
}

// ============================================================
// パスワード変更セクション
// ============================================================
class _PasswordSection extends ConsumerStatefulWidget {
  const _PasswordSection();

  @override
  ConsumerState<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<_PasswordSection> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isSaving       = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // バリデーション
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいパスワードが一致しません')),
      );
      return;
    }
    if (_newCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードは8文字以上で設定してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ログインが必要です');

      // 再認証（パスワード変更には再認証が必要）
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentCtrl.text,
      );
      await user.reauthenticateWithCredential(cred);

      // パスワード変更
      await user.updatePassword(_newCtrl.text);

      if (!mounted) return;
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ パスワードを変更しました')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'wrong-password'        => '現在のパスワードが正しくありません',
        'weak-password'         => 'パスワードが弱すぎます（8文字以上）',
        'requires-recent-login' => '再度ログインしてからお試しください',
        _                       => 'エラー: ${e.message}',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// パスワードリセットメールを送信（現在のパスワードを忘れた場合）
  Future<void> _sendResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスが設定されていません')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ ${user.email} にリセットメールを送信しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('送信失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // メール/パスワード連携済みかチェック
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.maybeWhen(data: (u) => u, orElse: () => null);
    final hasPassword = user?.providerData
            .any((p) => p.providerId == 'password') ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'パスワード変更',
          subtitle: 'メール/パスワード認証のパスワードを変更します',
        ),
        if (!hasPassword)
          // パスワード未設定の場合（SNSのみログイン）
          _WebSettingsCard(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Color(0xFF856404)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('メール/パスワードが未設定',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CardsColors.textMain)),
                        SizedBox(height: 4),
                        Text(
                          '現在はSNSログインのみです。パスワードを設定するには「アカウント連携」からメール/パスワードを追加してください。',
                          style: TextStyle(
                              fontSize: 13, color: CardsColors.textSub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _WebSettingsCard(
            child: Column(
              children: [
                _PasswordField(
                  ctrl: _currentCtrl,
                  label: '現在のパスワード',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  ctrl: _newCtrl,
                  label: '新しいパスワード',
                  hint: '8文字以上',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  ctrl: _confirmCtrl,
                  label: '新しいパスワード（確認）',
                  hint: '同じパスワードを入力',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // パスワードを忘れた場合
                    TextButton(
                      onPressed: _sendResetEmail,
                      child: const Text('パスワードをお忘れの方',
                          style: TextStyle(
                              fontSize: 12, color: CardsColors.primary)),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _changePassword,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock_reset,
                              size: 16, color: Colors.white),
                      label: Text(_isSaving ? '変更中...' : 'パスワードを変更',
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CardsColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// ログアウト・危険操作セクション
// ============================================================
class _DangerSection extends ConsumerWidget {
  const _DangerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'アカウント操作',
          subtitle: 'ログアウトなどの操作を行います',
        ),
        _WebSettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                // ログアウト
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout,
                        color: CardsColors.red, size: 20),
                  ),
                  title: const Text('ログアウト',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CardsColors.textMain)),
                  subtitle: const Text('ログアウトすると再度ログインが必要になります',
                      style: TextStyle(
                          fontSize: 12, color: CardsColors.textSub)),
                  trailing: OutlinedButton(
                    onPressed: () => _confirmSignOut(context, ref),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CardsColors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ログアウト',
                        style: TextStyle(color: CardsColors.red)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('ログアウトすると再度ログインが必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: CardsColors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(signOutProvider.future);
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }
}

// ============================================================
// 共通Widget群
// ============================================================

/// カードコンテナ（白背景・ボーダー）
class _WebSettingsCard extends StatelessWidget {
  const _WebSettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CardsColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}

Widget _buildCard({required Widget child}) =>
    _WebSettingsCard(child: child);

/// アバター（名前の頭文字）
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    // 名前 or メールの頭文字を表示
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : email.isNotEmpty
            ? email[0].toUpperCase()
            : '?';
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: CardsColors.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: CardsColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(initial,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CardsColors.primary)),
      ),
    );
  }
}

/// 情報表示行
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: CardsColors.textSub)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '未設定',
              style: TextStyle(
                  fontSize: 14,
                  color: value.isNotEmpty
                      ? CardsColors.textMain
                      : const Color(0xFFCBD5E1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Web版編集フィールド
class _WebEditField extends StatelessWidget {
  const _WebEditField({
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CardsColors.textMid)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: CardsColors.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: CardsColors.textSub, fontSize: 13),
            prefixIcon:
                Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CardsColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CardsColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: CardsColors.primary, width: 2)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}

/// パスワード入力フィールド（目のアイコンつき）
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.ctrl,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.hint,
  });
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CardsColors.textMid)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: CardsColors.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: CardsColors.textSub, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline,
                size: 18, color: Color(0xFF94A3B8)),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: const Color(0xFF94A3B8)),
              onPressed: onToggle,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CardsColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CardsColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: CardsColors.primary, width: 2)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}

/// SNS連携行
class _SnsRow extends StatelessWidget {
  const _SnsRow({
    required this.icon,
    required this.name,
    required this.description,
    required this.isLinked,
    required this.onLink,
  });
  final Widget icon;
  final String name;
  final String description;
  final bool isLinked;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(width: 36, height: 36, child: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CardsColors.textMain)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: CardsColors.textSub)),
              ],
            ),
          ),
          if (isLinked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border:
                    Border.all(color: const Color(0xFF86EFAC)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: Color(0xFF22C55E)),
                  SizedBox(width: 4),
                  Text('連携済み',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: onLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: CardsColors.primaryLight,
                foregroundColor: CardsColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('連携する',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ── SNSアイコン ────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: const Center(
          child: Text('G',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDB4437))),
        ),
      );
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1877F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('f',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
      );
}

class _XIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('𝕏',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
      );
}

// ============================================================
// メールアプリ選択セクション（Web版専用）
// ============================================================
class _MailSection extends ConsumerWidget {
  const _MailSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsync = ref.watch(selectedMailAppProvider);
    final selected = selectedAsync.maybeWhen(
      data: (a) => a,
      orElse: () => kWebMailApps.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'メールアプリの設定',
          subtitle: '名刺詳細画面の「メール」をタップしたときに開くアプリを選びます',
        ),
        _WebSettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 説明バナー
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: CardsColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Web版ではメールアプリの新規タブで開きます。Gmail/Outlookはブラウザ上で直接開きます。',
                        style: TextStyle(
                            fontSize: 12, color: CardsColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // アプリ一覧
              ...kWebMailApps.map((app) {
                final isSelected = selected.id == app.id;
                return _MailAppRow(
                  app: app,
                  isSelected: isSelected,
                  onTap: () async {
                    await ref
                        .read(selectedMailAppProvider.notifier)
                        .select(app);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('✅ メールアプリを「${app.name}」に設定しました')),
                    );
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 動作確認ボタン
        _WebSettingsCard(
          child: Row(
            children: [
              const Icon(Icons.send_outlined,
                  size: 18, color: CardsColors.textSub),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('テスト送信',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CardsColors.textMain)),
                    Text(
                      '現在の設定：${selected.name} で開きます',
                      style: const TextStyle(
                          fontSize: 12, color: CardsColors.textSub),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _testOpen(context, selected),
                icon: const Icon(Icons.open_in_new,
                    size: 14, color: Colors.white),
                label: const Text('動作確認',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CardsColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// テスト用に test@example.com 宛にメール作成画面を開く
  Future<void> _testOpen(BuildContext context, MailApp app) async {
    final uri = app.composeUri('test@example.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開くことができませんでした')),
      );
    }
  }
}

/// メールアプリ選択行
class _MailAppRow extends StatelessWidget {
  const _MailAppRow({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });
  final MailApp app;
  final bool isSelected;
  final VoidCallback onTap;

  // アプリごとのアイコン
  static const _icons = {
    'gmail':      ('📧', Color(0xFFEA4335)),
    'outlook':    ('📨', Color(0xFF0072C6)),
    'yahoo':      ('📬', Color(0xFF6001D2)),
    'protonmail': ('🛡️', Color(0xFF6D4AFF)),
    'default':    ('✉️', CardsColors.textSub),
  };

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = _icons[app.id] ?? ('✉️', CardsColors.textSub);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CardsColors.primary.withOpacity(0.06)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? CardsColors.primary : CardsColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            // 名前 + 説明
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? CardsColors.primary
                              : CardsColors.textMain)),
                  Text(
                    _description(app.id),
                    style: const TextStyle(
                        fontSize: 11, color: CardsColors.textSub),
                  ),
                ],
              ),
            ),
            // 選択中インジケーター
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: CardsColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: 14, color: Colors.white),
              )
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  String _description(String id) {
    return switch (id) {
      'gmail'      => 'Gmail をブラウザの新規タブで開きます',
      'outlook'    => 'Outlook Web をブラウザの新規タブで開きます',
      'yahoo'      => 'Yahoo Mail をブラウザの新規タブで開きます',
      'protonmail' => 'Proton Mail をブラウザの新規タブで開きます',
      _            => 'ブラウザのデフォルトメールアプリを開きます',
    };
  }
}
