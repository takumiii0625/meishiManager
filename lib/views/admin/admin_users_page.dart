import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// ----------------------------------------------------------------
// カラー定数
// ----------------------------------------------------------------
class _C {
  static const primary = Color(0xFF4361EE);
  static const primaryLight = Color(0xFFEEF1FD);
  static const bg = Color(0xFFFFFFFF);
  static const white = Colors.white;
  static const border = Color(0xFFE8EAF0);
  static const textMain = Color(0xFF1A1F36);
  static const textSub = Color(0xFF9396A5);
  static const textMid = Color(0xFF6B6F82);
  static const green = Color(0xFF1A8C4E);
  static const greenBg = Color(0xFFE6F9EE);
  static const amber = Color(0xFFB07D00);
  static const amberBg = Color(0xFFFFF8E6);
  static const red = Color(0xFFE53E3E);
  static const redBg = Color(0xFFFFF5F5);
}

// ----------------------------------------------------------------
// AdminUsersPage
// ----------------------------------------------------------------
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all'; // 'all' | 'active' | 'suspended'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------
  // アクセスログ記録
  // ----------------------------------------------------------------
  Future<void> _writeAccessLog({
    required String targetUserId,
    required String action,
    String detail = '',
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    // 管理者名をFirestoreから取得（なければメールアドレスを使用）
    String adminName = admin.email ?? admin.uid;
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(admin.uid)
          .get();
      if (adminDoc.exists) {
        adminName = adminDoc.data()?['name'] ?? adminName;
      }
    } catch (_) {}

    await FirebaseFirestore.instance.collection('admin_access_logs').add({
      'adminUid': admin.uid,
      'adminName': adminName,
      'targetUserId': targetUserId,
      'action': action,
      'detail': detail,
      'accessedAt': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------------
  // ステータスバッジ
  // ----------------------------------------------------------------
  Widget _statusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _C.greenBg : _C.amberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? '有効' : '停止中',
        style: TextStyle(
          color: isActive ? _C.green : _C.amber,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 権限バッジ
  // ----------------------------------------------------------------
  Widget _roleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? _C.primaryLight : const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? '管理者' : 'ユーザー',
        style: TextStyle(
          color: isAdmin ? _C.primary : _C.textMid,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // アバター
  // ----------------------------------------------------------------
  Widget _avatar(String name, int index) {
    const colors = [
      Color(0xFF4361EE), Color(0xFF7C3AED), Color(0xFF059669),
      Color(0xFFD97706), Color(0xFF0891B2),
    ];
    final color = colors[index % colors.length];
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 名刺一覧モーダル
  // ----------------------------------------------------------------
  void _showCardsModal(BuildContext context, DocumentSnapshot userDoc) async {
    final data = userDoc.data() as Map<String, dynamic>;
    final userName = data['name'] ?? '不明';

    // ログ記録
    await _writeAccessLog(
      targetUserId: userDoc.id,
      action: 'view_cards',
      detail: '$userName の名刺一覧を閲覧',
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$userName の名刺一覧',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)),
                        const SizedBox(height: 4),
                        const Text('※ 閲覧ログが記録されます',
                            style: TextStyle(fontSize: 11, color: _C.red)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _C.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ログ通知バナー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEA),
                  border: Border.all(color: const Color(0xFFF6D860)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Color(0xFF92700A)),
                    SizedBox(width: 8),
                    Text(
                      'このアクセスは admin_access_logs に記録されました',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92700A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 名刺グリッド
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userDoc.id)
                      .collection('business_cards')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _C.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('名刺データがありません',
                            style: TextStyle(color: _C.textSub)),
                      );
                    }
                    final cards = snapshot.data!.docs;
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisExtent: 150,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, i) {
                        final c = cards[i].data() as Map<String, dynamic>;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            border: Border.all(color: _C.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _C.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (c['name'] ?? '?')[0],
                                        style: const TextStyle(
                                          color: _C.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['name'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: _C.textMain),
                                            overflow: TextOverflow.ellipsis),
                                        Text(c['company'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 11, color: _C.textSub),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (c['email'] != null)
                                Text('📧 ${c['email']}',
                                    style: const TextStyle(fontSize: 11, color: _C.textMid),
                                    overflow: TextOverflow.ellipsis),
                              if (c['phone'] != null)
                                Text('📞 ${c['phone']}',
                                    style: const TextStyle(fontSize: 11, color: _C.textMid)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // アクセスログ確認モーダル
  // ----------------------------------------------------------------
  void _showLogModal(BuildContext context, DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final userName = data['name'] ?? '不明';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('$userName のアクセスログ',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _C.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('admin_access_logs')
                      .where('targetUserId', isEqualTo: userDoc.id)
                      .orderBy('accessedAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _C.primary));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('エラー: ${snapshot.error}',
                            style: const TextStyle(color: _C.red, fontSize: 12)),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('ログがありません', style: TextStyle(color: _C.textSub)),
                      );
                    }
                    final logs = snapshot.data!.docs;
                    return SingleChildScrollView(
                      child: Table(
                        border: TableBorder(
                          horizontalInside: const BorderSide(color: _C.border),
                          bottom: const BorderSide(color: _C.border),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          // ヘッダー
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8F9FC)),
                            children: ['管理者', '操作', '詳細', '日時'].map((h) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Text(h,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _C.textSub,
                                      letterSpacing: 0.5)),
                            )).toList(),
                          ),
                          // データ
                          ...logs.map((log) {
                            final l = log.data() as Map<String, dynamic>;
                            final ts = l['accessedAt'] as Timestamp?;
                            final dt = ts != null
                                ? '${ts.toDate().year}/${ts.toDate().month.toString().padLeft(2, '0')}/${ts.toDate().day.toString().padLeft(2, '0')} ${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                                : '—';
                            return TableRow(
                              children: [
                                _logCell(l['adminName'] ?? '—', bold: true),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _C.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l['action'] ?? '—',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.primary,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                                _logCell(l['detail'] ?? '—'),
                                _logCell(dt, color: _C.textSub),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logCell(String text, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: color ?? _C.textMain,
      ),
    ),
  );

  // ----------------------------------------------------------------
  // 編集ダイアログ
  // ----------------------------------------------------------------
  void _showEditDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final emailCtrl = TextEditingController(text: data['email'] ?? '');
    final companyCtrl = TextEditingController(text: data['company'] ?? '');
    String selectedStatus = data['status'] ?? 'active';
    String selectedRole = data['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('ユーザー編集',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _C.textSub),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _formField('名前', nameCtrl),
                _formField('メールアドレス', emailCtrl),
                _formField('会社名', companyCtrl),
                const SizedBox(height: 4),
                _dropdownField(
                  'ステータス',
                  selectedStatus,
                  {'active': '有効', 'suspended': '停止中'},
                  (v) => setDialogState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  '権限',
                  selectedRole,
                  {'user': 'ユーザー', 'admin': '管理者'},
                  (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('キャンセル', style: TextStyle(color: _C.textSub)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final oldStatus = data['status'] ?? 'active';
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(doc.id)
                            .update({
                          'name': nameCtrl.text,
                          'email': emailCtrl.text,
                          'company': companyCtrl.text,
                          'status': selectedStatus,
                          'role': selectedRole,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        String detail = 'ユーザー情報を編集';
                        if (oldStatus != selectedStatus) {
                          detail = 'ステータス変更: $oldStatus → $selectedStatus';
                        }
                        await _writeAccessLog(
                          targetUserId: doc.id,
                          action: 'edit_user',
                          detail: detail,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('保存する',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl,
      {TextInputType? keyboardType}) =>
      Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMid)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: _C.textMain),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _C.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _C.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _C.primary)),
            filled: true,
            fillColor: _C.bg,
          ),
        ),
      ],
    ),
  );

  Widget _dropdownField(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMid)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: _C.textMain),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.primary)),
              filled: true,
              fillColor: _C.bg,
            ),
            items: options.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
          ),
        ],
      );

  // ----------------------------------------------------------------
  // 削除確認ダイアログ
  // ----------------------------------------------------------------
  Future<void> _confirmDelete(
      BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final userName = data['name'] ?? '不明';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('ユーザーを削除しますか？',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _C.textMain)),
              const SizedBox(height: 8),
              Text(
                '$userName を削除すると、登録された名刺データもすべて削除されます。この操作は取り消せません。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _C.textSub, height: 1.7),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _C.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('キャンセル',
                        style: TextStyle(color: _C.textSub)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('削除する',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await _writeAccessLog(
        targetUserId: doc.id,
        action: 'delete_user',
        detail: '$userName を削除',
      );
      // Firestoreからユーザードキュメントを削除
      await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName を削除しました'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ----------------------------------------------------------------
  // Build
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー ──
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ユーザー管理',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _C.textMain,
                              letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('登録ユーザーの確認・編集・削除',
                          style: TextStyle(fontSize: 13, color: _C.textSub)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('ユーザー追加',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── 統計カード ──
            _StatsRow(statusFilter: _statusFilter),
            const SizedBox(height: 24),

            // ── 検索・フィルター ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 13, color: _C.textMain),
                    decoration: InputDecoration(
                      hintText: '名前・メール・会社で検索...',
                      hintStyle:
                          const TextStyle(color: _C.textSub, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: _C.textSub),
                      filled: true,
                      fillColor: _C.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _C.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _C.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _C.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _C.white,
                    border: Border.all(color: _C.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      style: const TextStyle(fontSize: 13, color: _C.textMain),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('すべてのステータス')),
                        DropdownMenuItem(value: 'active', child: Text('有効')),
                        DropdownMenuItem(
                            value: 'suspended', child: Text('停止中')),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── テーブル ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _C.white,
                  border: Border.all(color: _C.border),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (FirebaseAuth.instance.currentUser == null) {
                      return const Center(
                          child: Text('ログインしていません',
                              style: TextStyle(color: _C.textSub)));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('エラー: ${snapshot.error}',
                              style: const TextStyle(color: _C.red)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: _C.primary));
                    }

                    final allUsers = snapshot.data?.docs ?? [];

                    // 検索・フィルター適用
                    final filtered = allUsers.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name = (d['name'] ?? '').toLowerCase();
                      final email = (d['email'] ?? '').toLowerCase();
                      final company = (d['company'] ?? '').toLowerCase();
                      final status = d['status'] ?? 'active';
                      final q = _searchQuery.toLowerCase();
                      final matchSearch = q.isEmpty ||
                          name.contains(q) ||
                          email.contains(q) ||
                          company.contains(q);
                      final matchStatus =
                          _statusFilter == 'all' || status == _statusFilter;
                      return matchSearch && matchStatus;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('該当するユーザーが見つかりません',
                            style: TextStyle(color: _C.textSub)),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF8F9FC)),
                          headingTextStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textSub,
                            letterSpacing: 0.5,
                          ),
                          dataTextStyle: const TextStyle(
                              fontSize: 13, color: _C.textMain),
                          dividerThickness: 1,
                          horizontalMargin: 16,
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('ユーザー')),
                            DataColumn(label: Text('権限')),
                            DataColumn(label: Text('ステータス')),
                            DataColumn(label: Text('操作')),
                          ],
                          rows: filtered.asMap().entries.map((entry) {
                            final i = entry.key;
                            final doc = entry.value;
                            final d = doc.data() as Map<String, dynamic>;
                            final name = d['name'] ?? '未設定';
                            final email = d['email'] ?? '';
                            final role = d['role'] ?? 'user';
                            final status = d['status'] ?? 'active';

                            return DataRow(
                              color: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.hovered)
                                        ? const Color(0xFFF8F9FC)
                                        : Colors.white,
                              ),
                              cells: [
                                // ユーザー
                                DataCell(Row(
                                  children: [
                                    _avatar(name, i),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        Text(email,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: _C.textSub)),
                                      ],
                                    ),
                                  ],
                                )),
                                // 権限
                                DataCell(_roleBadge(role)),
                                // ステータス
                                DataCell(_statusBadge(status)),
                                // 操作ボタン
                                DataCell(Row(
                                  children: [
                                    _actionButton(
                                      Icons.style_outlined,
                                      '名刺一覧',
                                      _C.primaryLight,
                                      _C.primary,
                                      () => _showCardsModal(context, doc),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      Icons.edit_outlined,
                                      '編集',
                                      const Color(0xFFF2F3F7),
                                      _C.textMid,
                                      () => _showEditDialog(context, doc),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      Icons.history,
                                      'ログ確認',
                                      const Color(0xFFF2F3F7),
                                      _C.textMid,
                                      () => _showLogModal(context, doc),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      Icons.delete_outline,
                                      '削除',
                                      _C.redBg,
                                      _C.red,
                                      () => _confirmDelete(context, doc),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String tooltip,
    Color bg,
    Color color,
    VoidCallback onTap,
  ) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      );

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    String selectedRole = 'user';
    bool isLoading = false;
    bool obscurePassword = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                Row(
                  children: [
                    const Expanded(
                      child: Text('ユーザー追加',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.textMain)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _C.textSub),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '※ 初期パスワードはユーザーに別途お知らせください',
                  style: TextStyle(fontSize: 11, color: _C.textSub),
                ),
                const SizedBox(height: 20),

                // エラーメッセージ
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.redBg,
                      border: Border.all(color: _C.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: _C.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(errorMessage!,
                              style: const TextStyle(fontSize: 12, color: _C.red)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // フォーム
                _formField('名前', nameCtrl),
                _formField('メールアドレス', emailCtrl, keyboardType: TextInputType.emailAddress),
                _formField('会社名（任意）', companyCtrl),

                // パスワードフィールド（表示切替付き）
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('初期パスワード',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMid)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        style: const TextStyle(fontSize: 13, color: _C.textMain),
                        decoration: InputDecoration(
                          hintText: '8文字以上',
                          hintStyle: const TextStyle(color: _C.textSub, fontSize: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                              color: _C.textSub,
                            ),
                            onPressed: () =>
                                setDialogState(() => obscurePassword = !obscurePassword),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _C.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _C.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _C.primary)),
                          filled: true,
                          fillColor: _C.bg,
                        ),
                      ),
                    ],
                  ),
                ),

                // 権限選択
                _dropdownField(
                  '権限',
                  selectedRole,
                  {'user': 'ユーザー', 'admin': '管理者'},
                  (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 24),

                // フッター
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('キャンセル',
                          style: TextStyle(color: _C.textSub)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              // バリデーション
                              if (nameCtrl.text.trim().isEmpty) {
                                setDialogState(() => errorMessage = '名前を入力してください');
                                return;
                              }
                              if (emailCtrl.text.trim().isEmpty) {
                                setDialogState(() => errorMessage = 'メールアドレスを入力してください');
                                return;
                              }
                              if (passwordCtrl.text.length < 8) {
                                setDialogState(() => errorMessage = 'パスワードは8文字以上で入力してください');
                                return;
                              }

                              setDialogState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              FirebaseApp? tempApp;
                              try {
                                // ① 別インスタンスを作成
                                tempApp = await Firebase.initializeApp(
                                  name: 'tempUserCreation_${DateTime.now().millisecondsSinceEpoch}',
                                  options: Firebase.app().options,
                                );

                                // ② 別インスタンスでユーザー作成（管理者のセッションに影響なし）
                                final credential = await FirebaseAuth.instanceFor(app: tempApp)
                                    .createUserWithEmailAndPassword(
                                  email: emailCtrl.text.trim(),
                                  password: passwordCtrl.text,
                                );

                                final uid = credential.user!.uid;

                                // ③ Firestoreにユーザー情報を保存
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .set({
                                  'uid': uid,
                                  'name': nameCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'company': companyCtrl.text.trim(),
                                  'role': selectedRole,
                                  'status': 'active',
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                                // ④ アクセスログ記録
                                await _writeAccessLog(
                                  targetUserId: uid,
                                  action: 'create_user',
                                  detail: '${nameCtrl.text.trim()} を新規作成',
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${nameCtrl.text.trim()} を追加しました'),
                                      backgroundColor: _C.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                String msg = 'ユーザー作成に失敗しました';
                                if (e.code == 'email-already-in-use') {
                                  msg = 'このメールアドレスはすでに使用されています';
                                } else if (e.code == 'invalid-email') {
                                  msg = 'メールアドレスの形式が正しくありません';
                                } else if (e.code == 'weak-password') {
                                  msg = 'パスワードが弱すぎます。8文字以上にしてください';
                                }
                                setDialogState(() => errorMessage = msg);
                              } catch (e) {
                                setDialogState(
                                    () => errorMessage = 'エラーが発生しました: $e');
                              } finally {
                                // ⑤ 別インスタンスを必ず破棄
                                await tempApp?.delete();
                                setDialogState(() => isLoading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('追加する',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// 統計カードウィジェット（Firestoreからリアルタイム取得）
// ----------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  final String statusFilter;
  const _StatsRow({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final active = docs
            .where((d) => (d.data() as Map)['status'] == 'active')
            .length;
        final suspended = docs
            .where((d) => (d.data() as Map)['status'] == 'suspended')
            .length;

        return Row(
          children: [
            _statCard('総ユーザー数', total.toString(), const Color(0xFF4361EE),
                Icons.people_outline),
            const SizedBox(width: 16),
            _statCard(
                '有効', active.toString(), const Color(0xFF1A8C4E), Icons.check_circle_outline),
            const SizedBox(width: 16),
            _statCard('停止中', suspended.toString(), const Color(0xFFB07D00),
                Icons.pause_circle_outline),
          ],
        );
      },
    );
  }

  Widget _statCard(
          String label, String value, Color accent, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8EAF0)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // アクセントライン
                  Container(
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(value,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: accent)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9396A5))),
                ],
              ),
              Positioned(
                right: 0,
                top: 16,
                child: Icon(icon, size: 32, color: accent.withOpacity(0.15)),
              ),
            ],
          ),
        ),
      );
}
