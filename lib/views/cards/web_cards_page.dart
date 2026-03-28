import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/card_providers.dart';
import 'components/add_card_dialog.dart';
import 'components/cards_theme.dart';
import 'components/delete_card_dialog.dart';

class WebCardsPage extends ConsumerStatefulWidget {
  const WebCardsPage({super.key});

  @override
  ConsumerState<WebCardsPage> createState() => _WebCardsPageState();
}

class _WebCardsPageState extends ConsumerState<WebCardsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── ログアウト ──
  Future<void> _signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // ── 名刺追加ダイアログ ──
  void _showAddCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCardDialog(),
    );
  }

  // ── 削除確認ダイアログ ──
  void _showDeleteDialog(BuildContext context, card) {
    showDialog(
      context: context,
      builder: (context) => DeleteCardDialog(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final cardsAsync = uid.isEmpty
        ? const AsyncValue<List>.loading()
        : ref.watch(cardsStreamProvider);

    return Scaffold(
      backgroundColor: CardsColors.bg,
      body: Column(
        children: [
          // ── ヘッダー ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: CardsColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🪪', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Meishi Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CardsColors.primary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddCardDialog(context),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('名刺を追加',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CardsColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout,
                      size: 16, color: CardsColors.textMid),
                  label: const Text('ログアウト',
                      style: TextStyle(color: CardsColors.textMid)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CardsColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CardsColors.border),

          // ── メインコンテンツ ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル・件数
                  Row(
                    children: [
                      const Text(
                        '名刺一覧',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: CardsColors.textMain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      cardsAsync.when(
                        data: (cards) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: CardsColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${cards.length}件',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CardsColors.primary,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 検索
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                          fontSize: 13, color: CardsColors.textMain),
                      decoration: InputDecoration(
                        hintText: '名前・会社名で検索...',
                        hintStyle: const TextStyle(
                            color: CardsColors.textSub, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: CardsColors.textSub),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: CardsColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: CardsColors.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: CardsColors.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // テーブル
                  Expanded(
                    child: cardsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: CardsColors.primary)),
                      error: (e, _) => Center(
                          child: Text('エラー: $e',
                              style: const TextStyle(
                                  color: CardsColors.red))),
                      data: (cards) {
                        final filtered = cards.where((c) {
                          final q = _searchQuery.toLowerCase();
                          if (q.isEmpty) return true;
                          return c.name.toLowerCase().contains(q) ||
                              c.company.toLowerCase().contains(q);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🪪',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'まだ名刺が登録されていません'
                                      : '「$_searchQuery」に一致する名刺はありません',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: CardsColors.textSub),
                                ),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddCardDialog(context),
                                    icon: const Icon(Icons.add,
                                        size: 16, color: Colors.white),
                                    label: const Text('名刺を追加',
                                        style:
                                            TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CardsColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: CardsColors.border),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF8F9FC)),
                                headingTextStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: CardsColors.textSub,
                                  letterSpacing: 0.5,
                                ),
                                dataTextStyle: const TextStyle(
                                    fontSize: 13,
                                    color: CardsColors.textMain),
                                dividerThickness: 1,
                                horizontalMargin: 24,
                                columnSpacing: 32,
                                columns: const [
                                  DataColumn(label: Text('名前')),
                                  DataColumn(label: Text('会社名')),
                                  DataColumn(label: Text('メール')),
                                  DataColumn(label: Text('電話番号')),
                                  DataColumn(label: Text('操作')),
                                ],
                                rows: filtered.map((card) {
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.hovered)
                                              ? const Color(0xFFF8F9FC)
                                              : Colors.white,
                                    ),
                                    cells: [
                                      DataCell(Row(children: [
                                        _avatar(card.name),
                                        const SizedBox(width: 10),
                                        Text(card.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ])),
                                      DataCell(Text(
                                        card.company.isNotEmpty
                                            ? card.company
                                            : '—',
                                        style: TextStyle(
                                          color: card.company.isNotEmpty
                                              ? CardsColors.textMain
                                              : CardsColors.textSub,
                                        ),
                                      )),
                                      DataCell(Text(
                                        card.email.isNotEmpty
                                            ? card.email
                                            : '—',
                                        style: TextStyle(
                                          color: card.email.isNotEmpty
                                              ? CardsColors.primary
                                              : CardsColors.textSub,
                                        ),
                                      )),
                                      DataCell(Text(
                                        card.phone.isNotEmpty
                                            ? card.phone
                                            : '—',
                                        style: TextStyle(
                                          color: card.phone.isNotEmpty
                                              ? CardsColors.textMain
                                              : CardsColors.textSub,
                                        ),
                                      )),
                                      DataCell(_iconBtn(
                                        icon: Icons.delete_outline,
                                        color: CardsColors.red,
                                        bg: CardsColors.redBg,
                                        tooltip: '削除',
                                        onTap: () =>
                                            _showDeleteDialog(context, card),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name) => Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: CardsColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(
              color: CardsColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      );

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
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
}
