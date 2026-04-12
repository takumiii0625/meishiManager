// ============================================================
// cards_page.dart
// 名刺一覧画面（メイン画面）
//
// 【画面構成】
//   AppBar：タイトル + 検索アイコン + ゴミ箱アイコン（右上）
//   TabBar：すべて / 業種 / 地域 / タグ（4タブ）
//   サブフィルター：新しい順▼ / 地域▼ / 部署▼ / 役職▼
//     ※どのタブにいても横断絞り込みができる
//   一覧：タブに応じてグループ表示
//
// 【検索】
//   AppBar右上の検索アイコン → _SearchPage（インライン検索画面）
//   氏名・会社・部署・役職・業種・メモで横断検索
//
// 【ゴミ箱】
//   AppBar右上のゴミ箱アイコンから専用画面（_TrashPage）へ遷移
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card_model.dart';
import '../../providers/card_providers.dart';
import '../../widgets/card_image.dart';
import 'card_detail_page.dart';
import '../ocr/multi_scan_page.dart';

// ── フィルター状態 ─────────────────────────────────────────
class _FilterState {
  final String jobLevel;    // 役職フィルター
  final String department;  // 部署フィルター
  final String prefecture;  // 地域フィルター
  final String industry;    // ★ 業種フィルター（新規追加）
  final bool sortNewest;

  const _FilterState({
    this.jobLevel = '',
    this.department = '',
    this.prefecture = '',
    this.industry = '',
    this.sortNewest = true,
  });

  _FilterState copyWith({
    String? jobLevel,
    String? department,
    String? prefecture,
    String? industry,
    bool? sortNewest,
  }) =>
      _FilterState(
        jobLevel:   jobLevel   ?? this.jobLevel,
        department: department ?? this.department,
        prefecture: prefecture ?? this.prefecture,
        industry:   industry   ?? this.industry,
        sortNewest: sortNewest ?? this.sortNewest,
      );
}

class _FilterNotifier extends StateNotifier<_FilterState> {
  _FilterNotifier() : super(const _FilterState());

  void setJobLevel(String v) =>
      state = state.copyWith(jobLevel: state.jobLevel == v ? '' : v);

  // 部署フィルターをセット（同じ値を再タップしたら解除）
  void setDepartment(String v) =>
      state = state.copyWith(department: state.department == v ? '' : v);

  void setPrefecture(String v) =>
      state = state.copyWith(prefecture: state.prefecture == v ? '' : v);

  // ★ 業種フィルターをセット（同じ値を再タップしたら解除）
  void setIndustry(String v) =>
      state = state.copyWith(industry: state.industry == v ? '' : v);

  void toggleSort() =>
      state = state.copyWith(sortNewest: !state.sortNewest);

  void reset() => state = const _FilterState();
}

final _filterProvider =
    StateNotifierProvider.autoDispose<_FilterNotifier, _FilterState>(
  (ref) => _FilterNotifier(),
);

enum _GroupBy { industry, region, tag }

// ── メイン画面 ─────────────────────────────────────────────
class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});

  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsStreamProvider);
    final trashAsync = ref.watch(trashCardsStreamProvider);
    final filter = ref.watch(_filterProvider);
    final notifier = ref.read(_filterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text('名刺管理',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // ── 検索ボタン ──────────────────────────────────
          // タップで _SearchPage を開く
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () {
              // cardsAsync のデータを渡して検索画面を開く
              final cards = cardsAsync.maybeWhen(
                data: (c) => c,
                orElse: () => <CardModel>[],
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _SearchPage(allCards: cards),
                ),
              );
            },
          ),
          // ── ゴミ箱ボタン ────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'ゴミ箱',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _TrashPage()),
                ),
              ),
              trashAsync.maybeWhen(
                data: (trash) => trash.isEmpty
                    ? const SizedBox.shrink()
                    : Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: '業種'),
            Tab(text: '地域'),
            Tab(text: 'タグ'),
          ],
        ),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (cards) {
          final filtered = _applyFilter(cards, filter);

          // 実データから各フィルターの選択肢を動的生成
          final prefectures = cards
              .map((c) => c.prefecture)
              .where((p) => p.isNotEmpty)
              .toSet().toList()..sort();

          final departments = cards
              .map((c) => c.department)
              .where((d) => d.isNotEmpty)
              .toSet().toList()..sort();

          final jobLevels = cards
              .map((c) => c.jobLevel)
              .where((j) => j.isNotEmpty)
              .toSet().toList()..sort();

          // ★ 業種リスト（実データから動的生成）
          final industries = cards
              .map((c) => c.industry)
              .where((i) => i.isNotEmpty)
              .toSet().toList()..sort();

          return Column(
            children: [
              _SubFilterBar(
                filter: filter,
                notifier: notifier,
                prefectures: prefectures,
                departments: departments,
                jobLevels: jobLevels,
                industries: industries, // ★ 業種リストを渡す
              ),
              // フィルター適用中バナー
              if (filter.jobLevel.isNotEmpty ||
                  filter.department.isNotEmpty ||
                  filter.prefecture.isNotEmpty ||
                  filter.industry.isNotEmpty) // ★ 業種もバナー表示対象に
                _ActiveFilterBanner(filter: filter, notifier: notifier),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CardListView(cards: filtered, groupBy: null),
                    _CardListView(cards: filtered, groupBy: _GroupBy.industry),
                    _CardListView(cards: filtered, groupBy: _GroupBy.region),
                    _CardListView(cards: filtered, groupBy: _GroupBy.tag),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        tooltip: '名刺を追加',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            // maxBatchSize は省略 → デフォルトの10枚が使われる
            builder: (_) => const MultiScanPage(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<CardModel> _applyFilter(List<CardModel> cards, _FilterState filter) {
    var result = [...cards];

    if (filter.jobLevel.isNotEmpty) {
      result = result.where((c) => c.jobLevel == filter.jobLevel).toList();
    }
    if (filter.department.isNotEmpty) {
      result = result.where((c) => c.department == filter.department).toList();
    }
    if (filter.prefecture.isNotEmpty) {
      result = result.where((c) => c.prefecture == filter.prefecture).toList();
    }
    // ★ 業種フィルター追加
    if (filter.industry.isNotEmpty) {
      result = result.where((c) => c.industry == filter.industry).toList();
    }
    result.sort((a, b) => filter.sortNewest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return result;
  }
}

// ── サブフィルターバー ─────────────────────────────────────
class _SubFilterBar extends StatelessWidget {
  final _FilterState filter;
  final _FilterNotifier notifier;
  final List<String> prefectures;
  final List<String> departments;
  final List<String> jobLevels;
  final List<String> industries; // ★ 業種リスト

  const _SubFilterBar({
    required this.filter,
    required this.notifier,
    required this.prefectures,
    required this.departments,
    required this.jobLevels,
    required this.industries, // ★
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 並び順
            _Chip(
              label: filter.sortNewest ? '新しい順 ↓' : '古い順 ↑',
              isActive: true,
              onTap: notifier.toggleSort,
            ),
            const SizedBox(width: 8),
            // 地域
            _DropdownChip(
              label: filter.prefecture.isNotEmpty ? filter.prefecture : '地域 ▼',
              isActive: filter.prefecture.isNotEmpty,
              items: [
                const PopupMenuItem(value: '', child: Text('すべての地域')),
                ...prefectures.map((p) => PopupMenuItem(value: p, child: Text(p))),
              ],
              onSelected: notifier.setPrefecture,
            ),
            const SizedBox(width: 8),
            // 部署フィルター
            _DropdownChip(
              label: filter.department.isNotEmpty ? filter.department : '部署 ▼',
              isActive: filter.department.isNotEmpty,
              items: [
                const PopupMenuItem(value: '', child: Text('すべての部署')),
                ...departments.map((d) => PopupMenuItem(value: d, child: Text(d))),
              ],
              onSelected: notifier.setDepartment,
            ),
            const SizedBox(width: 8),
            // ★ 業種フィルター（新規追加）
            _DropdownChip(
              label: filter.industry.isNotEmpty ? filter.industry : '業種 ▼',
              isActive: filter.industry.isNotEmpty,
              items: [
                const PopupMenuItem(value: '', child: Text('すべての業種')),
                ...industries.map((i) => PopupMenuItem(value: i, child: Text(i))),
              ],
              onSelected: notifier.setIndustry,
            ),
            const SizedBox(width: 8),
            // 役職
            _DropdownChip(
              label: filter.jobLevel.isNotEmpty ? filter.jobLevel : '役職 ▼',
              isActive: filter.jobLevel.isNotEmpty,
              items: [
                const PopupMenuItem(value: '', child: Text('すべての役職')),
                ...jobLevels.map((j) => PopupMenuItem(value: j, child: Text(j))),
              ],
              onSelected: notifier.setJobLevel,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF1E40AF) : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF1E40AF) : const Color(0xFF475569),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<PopupMenuEntry<String>> items;
  final void Function(String) onSelected;
  const _DropdownChip({
    required this.label, required this.isActive,
    required this.items, required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF1E40AF) : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF1E40AF) : const Color(0xFF475569),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}

// ── フィルター適用中バナー ─────────────────────────────────
class _ActiveFilterBanner extends StatelessWidget {
  final _FilterState filter;
  final _FilterNotifier notifier;
  const _ActiveFilterBanner({required this.filter, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: const Color(0xFFEFF6FF),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 14, color: Color(0xFF1E40AF)),
          const SizedBox(width: 4),
          const Text('絞り込み中:',
              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
          const SizedBox(width: 4),
          if (filter.prefecture.isNotEmpty) ...[
            _FilterBadge(
              label: filter.prefecture,
              onRemove: () => notifier.setPrefecture(filter.prefecture),
            ),
            const SizedBox(width: 4),
          ],
          // 部署バッジ
          if (filter.department.isNotEmpty) ...[
            _FilterBadge(
              label: filter.department,
              onRemove: () => notifier.setDepartment(filter.department),
            ),
            const SizedBox(width: 4),
          ],
          // ★ 業種バッジ
          if (filter.industry.isNotEmpty) ...[
            _FilterBadge(
              label: filter.industry,
              onRemove: () => notifier.setIndustry(filter.industry),
            ),
            const SizedBox(width: 4),
          ],
          // 役職バッジ
          if (filter.jobLevel.isNotEmpty) ...[
            _FilterBadge(
              label: filter.jobLevel,
              onRemove: () => notifier.setJobLevel(filter.jobLevel),
            ),
            const SizedBox(width: 4),
          ],
          const Spacer(),
          GestureDetector(
            onTap: notifier.reset,
            child: const Text('すべて解除',
                style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
          ),
        ],
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterBadge({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
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

// ── カードリスト ───────────────────────────────────────────
class _CardListView extends StatelessWidget {
  final List<CardModel> cards;
  final _GroupBy? groupBy;
  const _CardListView({required this.cards, required this.groupBy});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📭', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('名刺がありません', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    if (groupBy == null) {
      return ListView.builder(
        itemCount: cards.length,
        itemBuilder: (_, i) => _CardTile(card: cards[i]),
      );
    }

    final groups = <String, List<CardModel>>{};
    for (final card in cards) {
      final key = switch (groupBy!) {
        _GroupBy.industry => card.industry.isNotEmpty ? card.industry : 'その他',
        _GroupBy.region => card.prefecture.isNotEmpty ? card.prefecture : '地域不明',
        _GroupBy.tag => card.tags.isNotEmpty ? card.tags.first : 'タグなし',
      };
      (groups[key] ??= []).add(card);
    }

    return ListView(
      children: [
        for (final entry in groups.entries) ...[
          _GroupHeader(label: entry.key, count: entry.value.length, groupBy: groupBy!),
          for (final card in entry.value) _CardTile(card: card),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final _GroupBy groupBy;
  const _GroupHeader({required this.label, required this.count, required this.groupBy});

  String _icon() {
    if (groupBy == _GroupBy.region) return '📍';
    if (groupBy == _GroupBy.tag) return '🏷';
    const map = {
      'IT': '💻', 'ソフトウェア': '💻', '金融': '🏦', '保険': '🏦',
      '医療': '🏥', '製造': '🏭', '建設': '🏗', '不動産': '🏠',
      '教育': '📚', '小売': '🛒', '飲食': '🍽', '物流': '🚚',
      'メディア': '📢', '広告': '📢', 'コンサル': '💼',
    };
    for (final e in map.entries) {
      if (label.contains(e.key)) return e.value;
    }
    return '🏢';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF1F5F9),
      child: Row(
        children: [
          Text(_icon(), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardModel card;
  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CardDetailPage(cardId: card.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: CardImage(
                url: card.displayImageUrl,
                width: 56,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name.isNotEmpty ? card.name : '（名前なし）',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (card.company.isNotEmpty) card.company,
                      if (card.affiliationText.isNotEmpty) card.affiliationText,
                      if (card.prefecture.isNotEmpty) card.prefecture,
                    ].join(' / '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (card.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(
                        spacing: 4,
                        children: card.tags.take(3).map((t) => _TagBadge(label: t)).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  const _TagBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A))),
    );
  }
}

// ============================================================
// 検索画面
//
// 【検索対象】
//   氏名・会社名・部署・役職・業種・住所・メモ・タグ
//
// 【仕組み】
//   全カードを受け取り、テキストフィールドの入力に応じて
//   リアルタイムに絞り込んで表示する。
//   Firestoreへの問い合わせは行わず、クライアント側で絞り込む。
// ============================================================
class _SearchPage extends StatefulWidget {
  final List<CardModel> allCards; // CardsPage から渡される全件リスト

  const _SearchPage({required this.allCards});

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _ctrl = TextEditingController();
  List<CardModel> _results = [];

  @override
  void initState() {
    super.initState();
    // 最初は全件表示
    _results = widget.allCards;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // テキスト入力が変わるたびに呼ばれる絞り込み処理
  void _onChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = widget.allCards);
      return;
    }

    // 検索対象フィールド：氏名・会社・部署・役職・業種・住所・メモ・タグ
    setState(() {
      _results = widget.allCards.where((card) {
        return card.name.toLowerCase().contains(q) ||
            card.company.toLowerCase().contains(q) ||
            card.department.toLowerCase().contains(q) ||
            card.jobLevel.toLowerCase().contains(q) ||
            card.industry.toLowerCase().contains(q) ||
            card.address.toLowerCase().contains(q) ||
            card.notes.toLowerCase().contains(q) ||
            card.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        // AppBarの中にテキストフィールドを埋め込む
        title: TextField(
          controller: _ctrl,
          autofocus: true, // 開いたらすぐキーボードが出る
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: '氏名・会社・部署・役職・業種で検索',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
            border: InputBorder.none, // ボーダーなし
          ),
        ),
        actions: [
          // 入力をクリアするボタン
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 検索結果の件数表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFFF8FAFC),
            child: Text(
              _ctrl.text.isEmpty
                  ? '全 ${_results.length} 件'
                  : '「${_ctrl.text}」の検索結果：${_results.length} 件',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
          // 検索結果リスト
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('該当する名刺がありません',
                            style: TextStyle(color: Color(0xFF94A3B8))),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) => _SearchResultTile(card: _results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// 検索結果の1行
class _SearchResultTile extends StatelessWidget {
  final CardModel card;
  const _SearchResultTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CardDetailPage(cardId: card.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          children: [
            // サムネイル
            Container(
              width: 56,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: CardImage(
                url: card.displayImageUrl,
                width: 56,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name.isNotEmpty ? card.name : '（名前なし）',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (card.company.isNotEmpty) card.company,
                      if (card.affiliationText.isNotEmpty) card.affiliationText,
                      if (card.prefecture.isNotEmpty) card.prefecture,
                    ].join(' / '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ゴミ箱画面
// ============================================================
class _TrashPage extends ConsumerWidget {
  const _TrashPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashCardsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゴミ箱'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: trashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🗑', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('ゴミ箱は空です', style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFEF2F2),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('削除済み名刺 — 「戻す」で復元、「完全削除」で消去',
                          style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                    ),
                    TextButton(
                      onPressed: () => _confirmEmptyTrash(context, ref, cards),
                      child: const Text('すべて削除',
                          style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (_, i) => _TrashTile(card: cards[i]),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('すべて完全削除しますか？'),
        content: const Text('ゴミ箱の名刺をすべて完全に削除します。\nこの操作は取り消せません。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
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

class _TrashTile extends ConsumerWidget {
  final CardModel card;
  const _TrashTile({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFFEF2F2), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.delete, color: Color(0xFFFCA5A5), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name.isNotEmpty ? card.name : '（名前なし）',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (card.company.isNotEmpty)
                  Text(card.company,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFD1D5DB))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _restore(context, ref),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('戻す', style: TextStyle(fontSize: 11)),
          ),
          TextButton(
            onPressed: () => _confirmDelete(context, ref),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('完全削除', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(restoreFromTrashProvider(card.id).future);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('「${card.name}」を復元しました')));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('完全に削除しますか？'),
        content: Text('「${card.name}」を完全に削除します。\nこの操作は取り消せません。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(deleteCardProvider(card.id).future);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('完全に削除しました')));
  }
}
