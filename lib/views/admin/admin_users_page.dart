import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_providers.dart';
import 'components/add_user_dialog.dart';
import 'components/admin_theme.dart';
import 'components/delete_user_dialog.dart';
import 'components/edit_user_dialog.dart';
import 'components/user_cards_dialog.dart';
import 'components/user_logs_dialog.dart';

// ----------------------------------------------------------------
// AdminUsersPage
// ----------------------------------------------------------------
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all'; // 'all' | 'active' | 'suspended'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------
  // ステータスバッジ
  // ----------------------------------------------------------------
  Widget _statusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AdminColors.greenBg : AdminColors.amberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? '有効' : '停止中',
        style: TextStyle(
          color: isActive ? AdminColors.green : AdminColors.amber,
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
        color: isAdmin ? AdminColors.primaryLight : const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? '管理者' : 'ユーザー',
        style: TextStyle(
          color: isAdmin ? AdminColors.primary : AdminColors.textMid,
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
  // ── 名刺確認モーダル ──
  void _showCardsModal(BuildContext context, DocumentSnapshot userDoc) async {
    final data = userDoc.data() as Map<String, dynamic>;
    final userName = data['name'] ?? '不明';
    await ref.read(writeAccessLogProvider(WriteAccessLogParams(
      targetUserId: userDoc.id,
      action: 'view_cards',
      detail: '$userName の名刺一覧を閲覧',
    )).future);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => UserCardsDialog(userDoc: userDoc),
    );
  }

  // ── アクセスログ確認モーダル ──
  void _showLogModal(BuildContext context, DocumentSnapshot userDoc) {
    showDialog(
      context: context,
      builder: (context) => UserLogsDialog(userDoc: userDoc),
    );
  }

  // ----------------------------------------------------------------
  // 編集ダイアログ
  // ----------------------------------------------------------------
  // ── 編集ダイアログ ──
  void _showEditDialog(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(doc: doc),
    );
  }

  // ----------------------------------------------------------------
  // 削除確認ダイアログ
  // ----------------------------------------------------------------
  // ── 削除確認ダイアログ ──
  Future<void> _confirmDelete(
      BuildContext context, DocumentSnapshot doc) async {
    showDialog(
      context: context,
      builder: (context) => DeleteUserDialog(doc: doc),
    );
  }

  // ----------------------------------------------------------------
  // Build
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
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
                              color: AdminColors.textMain,
                              letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('登録ユーザーの確認・編集・削除',
                          style: TextStyle(fontSize: 13, color: AdminColors.textSub)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('ユーザー追加',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
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
            _StatsRow(statusFilter: ref.watch(adminStatusFilterProvider)),
            const SizedBox(height: 24),

            // ── 検索・フィルター ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => ref.read(adminSearchQueryProvider.notifier).state = v,
                    style: const TextStyle(fontSize: 13, color: AdminColors.textMain),
                    decoration: InputDecoration(
                      hintText: '名前・メール・会社で検索...',
                      hintStyle:
                          const TextStyle(color: AdminColors.textSub, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AdminColors.textSub),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AdminColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AdminColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AdminColors.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AdminColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      style: const TextStyle(fontSize: 13, color: AdminColors.textMain),
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
                  color: Colors.white,
                  border: Border.all(color: AdminColors.border),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
                  ],
                ),
                child: Builder(builder: (context) {
                  final usersAsync = ref.watch(adminUsersStreamProvider);
                  final searchQuery = ref.watch(adminSearchQueryProvider);
                  final statusFilter = ref.watch(adminStatusFilterProvider);
                  return usersAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: AdminColors.primary)),
                    error: (e, _) => Center(
                        child: Text('エラー: $e',
                            style: const TextStyle(color: AdminColors.red))),
                    data: (snapshot) {
                    final allUsers = snapshot.docs;

                    // 検索・フィルター適用
                    final filtered = allUsers.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name = (d['name'] ?? '').toLowerCase();
                      final email = (d['email'] ?? '').toLowerCase();
                      final company = (d['company'] ?? '').toLowerCase();
                      final status = d['status'] ?? 'active';
                      final q = searchQuery.toLowerCase();
                      final matchSearch = q.isEmpty ||
                          name.contains(q) ||
                          email.contains(q) ||
                          company.contains(q);
                      final matchStatus =
                          statusFilter == 'all' || status == statusFilter;
                      return matchSearch && matchStatus;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('該当するユーザーが見つかりません',
                            style: TextStyle(color: AdminColors.textSub)),
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
                            color: AdminColors.textSub,
                            letterSpacing: 0.5,
                          ),
                          dataTextStyle: const TextStyle(
                              fontSize: 13, color: AdminColors.textMain),
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
                                                color: AdminColors.textSub)),
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
                                      AdminColors.primaryLight,
                                      AdminColors.primary,
                                      () => _showCardsModal(context, doc),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      Icons.edit_outlined,
                                      '編集',
                                      const Color(0xFFF2F3F7),
                                      AdminColors.textMid,
                                      () => _showEditDialog(context, doc),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      Icons.history,
                                      'ログ確認',
                                      const Color(0xFFF2F3F7),
                                      AdminColors.textMid,
                                      () => _showLogModal(context, doc),
                                    ),
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      Icons.delete_outline,
                                      '削除',
                                      AdminColors.redBg,
                                      AdminColors.red,
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
                  );
                }),
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

  // ── ユーザー追加ダイアログ ──
  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddUserDialog(),
    );
  }
}

// ----------------------------------------------------------------
// 統計カードウィジェット（Firestoreからリアルタイム取得）
// ----------------------------------------------------------------
class _StatsRow extends ConsumerWidget {
  final String statusFilter;
  const _StatsRow({required this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersStreamProvider);
    return usersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshot) {
        final docs = snapshot.docs;
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
