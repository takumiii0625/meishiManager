// ============================================================
// web_cards_page.dart
// Web版 名刺一覧画面
//
// 【機能】
//   ・テキスト検索（氏名・会社・部署・役職・業種・住所・メモ）
//   ・フィルター（業種・地域・役職）
//   ・フィルター適用中バナー（✕ で個別解除）
//   ・チェックボックスで複数選択 → 選択した人だけCSV出力
//   ・行クリック（チェックボックス以外）→ 右側に詳細パネルを表示
//   ・全選択/全解除チェックボックス
//   ・名刺追加ダイアログ / 削除確認ダイアログ
// ============================================================

// ignore: avoid_web_libraries_in_flutter
import 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/card_providers.dart';
import '../../services/mail_app_service.dart';
import 'components/add_card_dialog.dart';
import 'components/cards_theme.dart';
import 'components/delete_card_dialog.dart';
import 'components/web_card_detail_panel.dart';
import '../settings/web_settings_page.dart';

class WebCardsPage extends ConsumerStatefulWidget {
  const WebCardsPage({super.key});

  @override
  ConsumerState<WebCardsPage> createState() => _WebCardsPageState();
}

class _WebCardsPageState extends ConsumerState<WebCardsPage>
    with SingleTickerProviderStateMixin {
  // ── 検索・フィルター ──────────────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery      = '';
  String _filterIndustry   = '';
  String _filterPrefecture = '';
  String _filterJobLevel   = '';
  String _filterDepartment = ''; // 部署フィルター

  // ── タブ・並び替え ────────────────────────────────────────
  late final TabController _tabController;
  bool _sortNewest = true;

  // ── 詳細パネル表示用（1件）────────────────────────────────
  CardModel? _selectedCard;

  // ── CSV出力用チェック済みIDセット（複数件）────────────────
  // Set<String> = 重複なしのIDの集まり
  final Set<String> _checkedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── ログアウト ──────────────────────────────────────────
  Future<void> _signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  // ── ゴミ箱画面 ────────────────────────────────────────────
  void _openTrash() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _TrashPage()),
    );
  }

  // ── ダイアログ ──────────────────────────────────────────
  void _showAddCardDialog() =>
      showDialog(context: context, builder: (_) => const AddCardDialog());

  void _showDeleteDialog(CardModel card) =>
      showDialog(context: context, builder: (_) => DeleteCardDialog(card: card));

  // ── CSV出力 ─────────────────────────────────────────────
  // [cards] に渡したリストをCSVとしてダウンロードする
  void _exportCsv(List<CardModel> cards) {
    final rows = <String>['会社名,氏名,部署（役職）,業種,都道府県,メールアドレス,電話番号'];

    for (final card in cards) {
      // カンマ・ダブルクォート・改行を含む値をエスケープする
      String esc(String v) {
        if (v.contains(',') || v.contains('"') || v.contains('\n')) {
          return '"${v.replaceAll('"', '""')}"';
        }
        return v;
      }

      final affiliation =
          card.department.isNotEmpty && card.jobLevel.isNotEmpty
              ? '${card.department}(${card.jobLevel})'
              : card.department.isNotEmpty
                  ? card.department
                  : card.jobLevel;

      rows.add([
        esc(card.company),
        esc(card.name),
        esc(affiliation),
        esc(card.industry),
        esc(card.prefecture),
        esc(card.email),
        esc(card.phone),
      ].join(','));
    }

    // BOM付きUTF-8 → Excelで文字化けしない
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    downloadCsvOnWeb('\uFEFF${rows.join('\n')}', 'meishi_$dateStr.csv');
  }

  // ── フィルター適用 ──────────────────────────────────────
  List<CardModel> _applyFilter(List<CardModel> cards) {
    final result = cards.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.company.toLowerCase().contains(q) ||
          c.department.toLowerCase().contains(q) ||
          c.jobLevel.toLowerCase().contains(q) ||
          c.industry.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q) ||
          c.notes.toLowerCase().contains(q) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
      final matchIndustry   = _filterIndustry.isEmpty   || c.industry   == _filterIndustry;
      final matchPrefecture = _filterPrefecture.isEmpty || c.prefecture == _filterPrefecture;
      final matchJobLevel   = _filterJobLevel.isEmpty   || c.jobLevel   == _filterJobLevel;
      final matchDepartment = _filterDepartment.isEmpty || c.department == _filterDepartment;
      return matchSearch && matchIndustry && matchPrefecture && matchJobLevel && matchDepartment;
    }).toList();
    result.sort((a, b) => _sortNewest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return result;
  }

  bool get _hasActiveFilter =>
      _filterIndustry.isNotEmpty ||
      _filterPrefecture.isNotEmpty ||
      _filterJobLevel.isNotEmpty ||
      _filterDepartment.isNotEmpty;

  void _resetAllFilters() => setState(() {
        _filterIndustry = _filterPrefecture = _filterJobLevel = _filterDepartment = '';
      });

  // ── チェックボックス操作 ────────────────────────────────
  void _toggleCheck(String id) {
    setState(() {
      if (_checkedIds.contains(id)) {
        _checkedIds.remove(id);
      } else {
        _checkedIds.add(id);
      }
    });
  }

  // 全選択 / 全解除
  void _toggleCheckAll(List<CardModel> cards) {
    final allIds = cards.map((c) => c.id).toSet();
    setState(() {
      if (_checkedIds.containsAll(allIds)) {
        // 全部チェック済み → 全解除
        _checkedIds.removeAll(allIds);
      } else {
        // 一部または0件 → 全選択
        _checkedIds.addAll(allIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final cardsAsync = uid.isEmpty
        ? const AsyncValue<List<CardModel>>.loading()
        : ref.watch(cardsStreamProvider);

    return Scaffold(
      backgroundColor: CardsColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: CardsColors.border),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: cardsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: CardsColors.primary)),
                    error: (e, _) => Center(
                        child: Text('エラー: $e',
                            style: const TextStyle(color: CardsColors.red))),
                    data: (cards) => _buildListArea(cards),
                  ),
                ),
                if (_selectedCard != null)
                  WebCardDetailPanel(
                    key: ValueKey(_selectedCard!.id),
                    card: _selectedCard!,
                    onClose: () => setState(() => _selectedCard = null),
                  ),
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
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: CardsColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🪪', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          const Text('Meishi Manager',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CardsColors.primary)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('名刺を追加',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: CardsColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 8),
          // ゴミ箱
          OutlinedButton.icon(
            onPressed: _openTrash,
            icon: const Icon(Icons.delete_outline, size: 16, color: CardsColors.textMid),
            label: const Text('ゴミ箱', style: TextStyle(color: CardsColors.textMid)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CardsColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // 設定ボタン
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WebSettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined,
                size: 16, color: CardsColors.textMid),
            label: const Text('設定',
                style: TextStyle(color: CardsColors.textMid)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CardsColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, size: 16, color: CardsColors.textMid),
            label: const Text('ログアウト',
                style: TextStyle(color: CardsColors.textMid)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CardsColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── 一覧エリア ──────────────────────────────────────────
  Widget _buildListArea(List<CardModel> allCards) {
    final filtered    = _applyFilter(allCards);
    final checkedInView = filtered.where((c) => _checkedIds.contains(c.id)).toList();
    final allChecked  = filtered.isNotEmpty &&
        filtered.every((c) => _checkedIds.contains(c.id));
    final someChecked = filtered.any((c) => _checkedIds.contains(c.id));

    final industries  = allCards.map((c) => c.industry).where((v) => v.isNotEmpty).toSet().toList()..sort();
    final prefectures = allCards.map((c) => c.prefecture).where((v) => v.isNotEmpty).toSet().toList()..sort();
    final jobLevels   = allCards.map((c) => c.jobLevel).where((v) => v.isNotEmpty).toSet().toList()..sort();
    final departments = allCards.map((c) => c.department).where((v) => v.isNotEmpty).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── タイトル行 ──────────────────────────────────
          Row(
            children: [
              const Text('名刺一覧',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: CardsColors.textMain)),
              const SizedBox(width: 10),
              _countBadge(filtered.length),
              const Spacer(),
              // 選択中がある場合 → 「選択した N 件を出力」ボタン（優先表示）
              if (someChecked) ...[
                ElevatedButton.icon(
                  onPressed: () => _exportCsv(checkedInView),
                  icon: const Icon(Icons.download, size: 16, color: Colors.white),
                  label: Text(
                    '選択した ${checkedInView.length} 件を出力',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CardsColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: 8),
                // 選択解除ボタン
                OutlinedButton(
                  onPressed: () => setState(() => _checkedIds.clear()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CardsColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  child: const Text('選択解除',
                      style: TextStyle(
                          color: CardsColors.textMid, fontSize: 13)),
                ),
                const SizedBox(width: 8),
              ],
              // 全件出力ボタン
              if (filtered.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _exportCsv(filtered),
                  icon: const Icon(Icons.download,
                      size: 16, color: CardsColors.textMid),
                  label: Text(
                    someChecked
                        ? '全件出力 (${filtered.length}件)'
                        : 'CSV出力 (${filtered.length}件)',
                    style: const TextStyle(
                        color: CardsColors.textMid, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CardsColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── タブ ────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: CardsColors.primary,
            unselectedLabelColor: CardsColors.textSub,
            indicatorColor: CardsColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'すべて'),
              Tab(text: '業種'),
              Tab(text: '地域'),
              Tab(text: 'タグ'),
            ],
          ),
          const Divider(height: 1, color: CardsColors.border),
          const SizedBox(height: 12),

          // ── 検索 + フィルター ────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(
                      fontSize: 13, color: CardsColors.textMain),
                  decoration: InputDecoration(
                    hintText: '氏名・会社・業種などで検索...',
                    hintStyle: const TextStyle(
                        color: CardsColors.textSub, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: CardsColors.textSub),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 16, color: CardsColors.textSub),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
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
              _FilterDropdown(
                label: _filterIndustry.isNotEmpty ? _filterIndustry : '業種 ▼',
                isActive: _filterIndustry.isNotEmpty,
                items: [
                  const PopupMenuItem(value: '', child: Text('すべての業種')),
                  ...industries.map((v) => PopupMenuItem(value: v, child: Text(v))),
                ],
                onSelected: (v) => setState(() => _filterIndustry = v),
              ),
              _FilterDropdown(
                label: _filterPrefecture.isNotEmpty
                    ? _filterPrefecture
                    : '地域 ▼',
                isActive: _filterPrefecture.isNotEmpty,
                items: [
                  const PopupMenuItem(value: '', child: Text('すべての地域')),
                  ...prefectures.map((v) => PopupMenuItem(value: v, child: Text(v))),
                ],
                onSelected: (v) => setState(() => _filterPrefecture = v),
              ),
              _FilterDropdown(
                label: _filterJobLevel.isNotEmpty ? _filterJobLevel : '役職 ▼',
                isActive: _filterJobLevel.isNotEmpty,
                items: [
                  const PopupMenuItem(value: '', child: Text('すべての役職')),
                  ...jobLevels.map((v) => PopupMenuItem(value: v, child: Text(v))),
                ],
                onSelected: (v) => setState(() => _filterJobLevel = v),
              ),
              _FilterDropdown(
                label: _filterDepartment.isNotEmpty ? _filterDepartment : '部署 ▼',
                isActive: _filterDepartment.isNotEmpty,
                items: [
                  const PopupMenuItem(value: '', child: Text('すべての部署')),
                  ...departments.map((v) => PopupMenuItem(value: v, child: Text(v))),
                ],
                onSelected: (v) => setState(() => _filterDepartment = v),
              ),
              // 並び替えボタン
              _FilterDropdown(
                label: _sortNewest ? '新しい順 ↓' : '古い順 ↑',
                isActive: false,
                items: [
                  const PopupMenuItem(value: 'newest', child: Text('新しい順')),
                  const PopupMenuItem(value: 'oldest', child: Text('古い順')),
                ],
                onSelected: (v) => setState(() => _sortNewest = v == 'newest'),
              ),
            ],
          ),

          // ── フィルター適用中バナー ────────────────────────
          if (_hasActiveFilter)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CardsColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: CardsColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list,
                        size: 14, color: CardsColors.primary),
                    const SizedBox(width: 6),
                    const Text('絞り込み中:',
                        style: TextStyle(
                            fontSize: 11, color: CardsColors.primary)),
                    const SizedBox(width: 6),
                    if (_filterIndustry.isNotEmpty)
                      _FilterBadge(
                          label: _filterIndustry,
                          onRemove: () =>
                              setState(() => _filterIndustry = '')),
                    if (_filterPrefecture.isNotEmpty)
                      _FilterBadge(
                          label: _filterPrefecture,
                          onRemove: () =>
                              setState(() => _filterPrefecture = '')),
                    if (_filterJobLevel.isNotEmpty)
                      _FilterBadge(
                          label: _filterJobLevel,
                          onRemove: () =>
                              setState(() => _filterJobLevel = '')),
                    if (_filterDepartment.isNotEmpty)
                      _FilterBadge(
                          label: _filterDepartment,
                          onRemove: () =>
                              setState(() => _filterDepartment = '')),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _resetAllFilters,
                      child: const Text('すべて解除',
                          style: TextStyle(
                              fontSize: 11,
                              color: CardsColors.primary,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── テーブル ──────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty()
                : _tabController.index == 0
                    ? _buildTable(filtered, allChecked, someChecked)
                    : _buildGroupedTable(filtered, allChecked, someChecked),
          ),
        ],
      ),
    );
  }

  // ── グループ表示 ─────────────────────────────────────────
  Widget _buildGroupedTable(
      List<CardModel> cards, bool allChecked, bool someChecked) {
    String keyOf(CardModel c) {
      switch (_tabController.index) {
        case 1: return c.industry.isNotEmpty ? c.industry : 'その他';
        case 2: return c.prefecture.isNotEmpty ? c.prefecture : '地域不明';
        case 3: return c.tags.isNotEmpty ? c.tags.first : 'タグなし';
        default: return '';
      }
    }
    String iconOf() {
      if (_tabController.index == 2) return '📍';
      if (_tabController.index == 3) return '🏷';
      return '🏢';
    }

    final grouped = <String, List<CardModel>>{};
    for (final c in cards) {
      grouped.putIfAbsent(keyOf(c), () => []).add(c);
    }
    final keys = grouped.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: keys.map((key) {
          final group = grouped[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(children: [
                  Text('${iconOf()} $key',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: CardsColors.textMain)),
                  const SizedBox(width: 8),
                  _countBadge(group.length),
                ]),
              ),
              _buildTable(group, allChecked, someChecked),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── 件数バッジ ──────────────────────────────────────────
  Widget _countBadge(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CardsColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$count件',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CardsColors.primary)),
      );

  // ── 空状態 ──────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            (_searchQuery.isNotEmpty || _hasActiveFilter)
                ? '条件に一致する名刺はありません'
                : 'まだ名刺が登録されていません',
            style: const TextStyle(fontSize: 15, color: CardsColors.textSub),
          ),
          if (_searchQuery.isEmpty && !_hasActiveFilter) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showAddCardDialog,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('名刺を追加',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: CardsColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── テーブル ────────────────────────────────────────────
  Widget _buildTable(
      List<CardModel> cards, bool allChecked, bool someChecked) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: CardsColors.border),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: constraints.maxWidth),
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
                      fontSize: 13, color: CardsColors.textMain),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 72,
                  dividerThickness: 1,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: [
                    // ヘッダーのチェックボックス列（全選択/全解除）
                    DataColumn(
                      label: Tooltip(
                        message: allChecked ? '全解除' : '全選択',
                        child: Checkbox(
                          value: allChecked
                              ? true
                              : someChecked
                                  ? null  // 一部選択 → 中間状態（-）
                                  : false,
                          tristate: true, // 中間状態（-）を許可
                          onChanged: (_) => _toggleCheckAll(cards),
                          activeColor: CardsColors.primary,
                        ),
                      ),
                    ),
                    const DataColumn(label: Text('名前')),
                    const DataColumn(label: Text('会社名 / 部署')),
                    const DataColumn(label: Text('業種')),
                    const DataColumn(label: Text('メール')),
                    const DataColumn(label: Text('電話番号')),
                    const DataColumn(label: Text('操作')),
                  ],
                  rows: cards.map((card) {
                    final isChecked = _checkedIds.contains(card.id);
                    final isPanelOpen = _selectedCard?.id == card.id;

                    return DataRow(
                      // チェック状態で行の背景色を変える
                      color: WidgetStateProperty.resolveWith((states) {
                        if (isChecked) {
                          return CardsColors.primaryLight;
                        }
                        if (isPanelOpen) {
                          return const Color(0xFFF0F4FF);
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xFFF8F9FC);
                        }
                        return Colors.white;
                      }),
                      cells: [
                        // チェックボックスセル
                        DataCell(
                          Checkbox(
                            value: isChecked,
                            onChanged: (_) => _toggleCheck(card.id),
                            activeColor: CardsColors.primary,
                          ),
                        ),
                        // 名前（クリックで詳細パネル表示）
                        DataCell(
                          GestureDetector(
                            onTap: () => setState(() =>
                                _selectedCard =
                                    isPanelOpen ? null : card),
                            child: Row(children: [
                              _avatar(card.name),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                    if (card.tags.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Wrap(
                                        spacing: 4,
                                        children: card.tags.take(3).map((tag) =>
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              border: Border.all(
                                                  color: const Color(0xFFBBF7D0)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(tag,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF16A34A))),
                                          ),
                                        ).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // 会社名 / 部署
                        DataCell(
                          GestureDetector(
                            onTap: () => setState(() =>
                                _selectedCard =
                                    isPanelOpen ? null : card),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.company.isNotEmpty
                                      ? card.company
                                      : '—',
                                  style: TextStyle(
                                      color: card.company.isNotEmpty
                                          ? CardsColors.textMain
                                          : CardsColors.textSub,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (card.affiliationText.isNotEmpty)
                                  Text(
                                    card.affiliationText,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: CardsColors.textSub),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 業種
                        DataCell(Text(
                          card.industry.isNotEmpty ? card.industry : '—',
                          style: TextStyle(
                              color: card.industry.isNotEmpty
                                  ? CardsColors.textMain
                                  : CardsColors.textSub),
                        )),
                        // メール
                        DataCell(
                          card.email.isNotEmpty
                              ? InkWell(
                                  onTap: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => _MailConfirmDialog(
                                          email: card.email),
                                    );
                                    if (confirmed == true) {
                                      final mailApp = ref
                                          .read(selectedMailAppProvider)
                                          .valueOrNull ?? kWebMailApps.first;
                                      await launchMailApp(mailApp, card.email);
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(card.email,
                                            style: const TextStyle(
                                              color: CardsColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  CardsColors.primary,
                                            ),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.mail_outline,
                                          size: 13, color: CardsColors.primary),
                                    ],
                                  ),
                                )
                              : const Text('—',
                                  style:
                                      TextStyle(color: CardsColors.textSub)),
                        ),
                        // 電話番号
                        DataCell(Text(
                          card.phone.isNotEmpty ? card.phone : '—',
                          style: TextStyle(
                              color: card.phone.isNotEmpty
                                  ? CardsColors.textMain
                                  : CardsColors.textSub),
                        )),
                        // 操作ボタン
                        DataCell(Row(children: [
                          _iconBtn(
                            icon: Icons.open_in_new,
                            color: CardsColors.primary,
                            bg: CardsColors.primaryLight,
                            tooltip: '詳細を表示',
                            onTap: () => setState(() =>
                                _selectedCard =
                                    isPanelOpen ? null : card),
                          ),
                          const SizedBox(width: 6),
                          _iconBtn(
                            icon: Icons.delete_outline,
                            color: CardsColors.red,
                            bg: CardsColors.redBg,
                            tooltip: '削除',
                            onTap: () => _showDeleteDialog(card),
                          ),
                        ])),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
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

// ── フィルタードロップダウン ──────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<PopupMenuEntry<String>> items;
  final void Function(String) onSelected;

  const _FilterDropdown({
    required this.label,
    required this.isActive,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? CardsColors.primaryLight : Colors.white,
          border: Border.all(
              color: isActive ? CardsColors.primary : CardsColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? CardsColors.primary : CardsColors.textMid,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── フィルターバッジ ──────────────────────────────────────────
class _FilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterBadge({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CardsColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// メール確認ダイアログ
// ================================================================
class _MailConfirmDialog extends StatelessWidget {
  final String email;
  const _MailConfirmDialog({required this.email});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline, size: 32, color: CardsColors.primary),
            const SizedBox(height: 12),
            const Text('メールを作成しますか？',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CardsColors.textMain)),
            const SizedBox(height: 8),
            Text(email,
                style: const TextStyle(
                    fontSize: 13, color: CardsColors.primary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CardsColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('キャンセル',
                        style: TextStyle(color: CardsColors.textSub)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CardsColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('メールを作成',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white)),
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

// ================================================================
// ゴミ箱画面
// ================================================================
class _TrashPage extends ConsumerWidget {
  const _TrashPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashCardsStreamProvider);
    return Scaffold(
      backgroundColor: CardsColors.bg,
      appBar: AppBar(
        title: const Text('ゴミ箱', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: CardsColors.textMain,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: CardsColors.border),
        ),
      ),
      body: trashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: CardsColors.primary)),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🗑', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('ゴミ箱は空です',
                      style: TextStyle(fontSize: 16, color: CardsColors.textSub)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: CardsColors.redBg,
                child: Row(children: [
                  const Expanded(
                    child: Text('削除済み名刺 — 「戻す」で復元、「完全削除」で消去',
                        style: TextStyle(fontSize: 12, color: CardsColors.red)),
                  ),
                  TextButton(
                    onPressed: () => _confirmEmptyTrash(context, ref, cards),
                    child: const Text('すべて削除',
                        style: TextStyle(fontSize: 12, color: CardsColors.red)),
                  ),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TrashCard(card: cards[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
      BuildContext context, WidgetRef ref, List<CardModel> cards) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('すべて完全削除しますか？'),
        content: const Text('ゴミ箱の名刺をすべて完全に削除します。\nこの操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CardsColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('すべて削除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    for (final card in cards) {
      await ref.read(deleteCardProvider(card.id).future);
    }
  }
}

class _TrashCard extends ConsumerWidget {
  final CardModel card;
  const _TrashCard({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CardsColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: CardsColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                card.name.isNotEmpty ? card.name[0] : '?',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: CardsColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: CardsColors.textMain)),
                Text(card.company,
                    style: const TextStyle(fontSize: 12, color: CardsColors.textSub)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              await ref.read(restoreFromTrashProvider(card.id).future);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${card.name} を復元しました'),
                  backgroundColor: CardsColors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CardsColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('戻す', style: TextStyle(color: CardsColors.primary, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('完全削除しますか？'),
                  content: Text('「${card.name}」を完全に削除します。\nこの操作は取り消せません。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: CardsColors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              await ref.read(deleteCardProvider(card.id).future);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: CardsColors.red.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('完全削除', style: TextStyle(color: CardsColors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
