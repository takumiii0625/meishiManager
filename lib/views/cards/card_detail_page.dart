// ============================================================
// card_detail_page.dart
// 名刺詳細画面
//
// 【遷移方法】
//   cards_page の _CardTile.onTap から右スライドで開く
//
// 【機能】
//   ・表面/裏面の画像切り替え（両方ある場合のみ）
//   ・氏名・会社・業種・連絡先・タグ表示
//   ・タグの追加・削除
//   ・編集ボタン → card_edit_page.dart へ
//   ・ゴミ箱ボタン → 論理削除（ゴミ箱タブに移動）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card_model.dart';
import '../../providers/card_providers.dart';
import 'card_edit_page.dart';

class CardDetailPage extends ConsumerWidget {
  const CardDetailPage({super.key, required this.cardId});

  /// 表示する名刺のFirestoreドキュメントID
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // cardStreamProvider でリアルタイムに名刺データを監視
    // 編集して保存すると自動でこの画面も更新される
    final cardAsync = ref.watch(cardStreamProvider(cardId));

    return cardAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('名刺詳細')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('名刺詳細')),
        body: Center(child: Text('エラー: $e')),
      ),
      data: (card) => _DetailContent(card: card),
    );
  }
}

// 詳細コンテンツを別Widgetに分離
// （cardがnullでないことが確定してから描画するため）
class _DetailContent extends ConsumerWidget {
  final CardModel card;
  const _DetailContent({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.name.isNotEmpty ? card.name : '名刺詳細'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          // 編集ボタン → card_edit_page.dart へ遷移
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '編集',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CardEditPage(card: card)),
            ),
          ),
          // ゴミ箱ボタン → 論理削除（一覧のゴミ箱タブに移動）
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'ゴミ箱に移動',
            onPressed: () => _confirmMoveToTrash(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── 名刺画像エリア（表面/裏面切り替え）────────────
          _ImageSection(card: card),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 氏名（大きく表示）
                Text(
                  card.name.isNotEmpty ? card.name : '（名前なし）',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B)),
                ),
                // 会社名
                if (card.company.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(card.company,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: const Color(0xFF475569))),
                  ),
                // 部署・役職（部署＞役職の優先度で表示。両方あれば両方表示）
                if (card.affiliationText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(card.affiliationText,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B))),
                  ),

                const Divider(height: 32),

                // ── 詳細情報の行リスト ──────────────────────
                if (card.industry.isNotEmpty)
                  _InfoRow(
                      icon: Icons.business,
                      label: '業種',
                      value: card.industry),
                // 部署（役職より優先度高）
                if (card.department.isNotEmpty)
                  _InfoRow(
                      icon: Icons.corporate_fare,
                      label: '部署',
                      value: card.department),
                // 役職（部署がない場合でも表示）
                if (card.jobLevel.isNotEmpty)
                  _InfoRow(
                      icon: Icons.badge_outlined,
                      label: '役職',
                      value: card.jobLevel),
                if (card.prefecture.isNotEmpty)
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: '地域',
                      value: card.prefecture),
                if (card.phone.isNotEmpty)
                  _InfoRow(
                      icon: Icons.phone_outlined,
                      label: '電話',
                      value: card.phone),
                if (card.email.isNotEmpty)
                  _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'メール',
                      value: card.email),
                if (card.address.isNotEmpty)
                  _InfoRow(
                      icon: Icons.map_outlined,
                      label: '住所',
                      value: card.address),
                if (card.notes.isNotEmpty)
                  _InfoRow(
                      icon: Icons.notes, label: 'メモ', value: card.notes),

                // ── タグエリア ──────────────────────────────
                const SizedBox(height: 16),
                _TagSection(card: card),

                // ── 登録日時 ────────────────────────────────
                const Divider(height: 32),
                Text(
                  '登録日: ${card.createdAt.year}年${card.createdAt.month}月${card.createdAt.day}日',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ゴミ箱に移動する確認ダイアログ
  Future<void> _confirmMoveToTrash(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ゴミ箱に移動しますか？'),
        content: Text(
            '「${card.name}」をゴミ箱に移動します。\nゴミ箱から復元することもできます。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ゴミ箱へ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // 論理削除（isDeleted=true にするだけ）
    await ref.read(moveToTrashProvider(card.id).future);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${card.name}」をゴミ箱に移動しました')));
    Navigator.of(context).pop(); // 詳細を閉じて一覧に戻る
  }
}

// ── 名刺画像セクション ────────────────────────────────────
class _ImageSection extends StatefulWidget {
  final CardModel card;
  const _ImageSection({required this.card});

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  bool _showFront = true; // true = 表面、false = 裏面

  @override
  Widget build(BuildContext context) {
    final hasFront = widget.card.frontImageUrl.isNotEmpty;
    final hasBack  = widget.card.backImageUrl.isNotEmpty;
    final url = _showFront
        ? widget.card.frontImageUrl
        : widget.card.backImageUrl;

    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── 名刺画像 ─────────────────────────────────────
          // AspectRatio を使わず ConstrainedBox + contain で表示する。
          // 理由:
          //   ・横名刺と縦名刺で縦横比が違うため固定比率にすると潰れる
          //   ・BoxFit.contain = 元の比率を保ったまま枠内に収める
          //   ・maxHeight で画面に収まるよう制限
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 280, // 縦名刺でもはみ出さないよう制限
                maxWidth: double.infinity,
              ),
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.contain, // 元の縦横比を維持して表示
                      errorBuilder: (_, __, ___) => _noImage(),
                    )
                  : _noImage(),
            ),
          ),
          // 表面/裏面の切り替えボタン（両方ある場合のみ表示）
          if (hasFront && hasBack)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ToggleButtons(
                isSelected: [_showFront, !_showFront],
                onPressed: (i) => setState(() => _showFront = i == 0),
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: const Color(0xFF1E40AF),
                color: const Color(0xFF475569),
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('表面', style: TextStyle(fontSize: 12))),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('裏面', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          // 画像がない場合の案内
          if (!hasFront && !hasBack)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('画像がありません',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),
        ],
      ),
    );
  }

  // 画像がない場合のプレースホルダー
  Widget _noImage() => Container(
        height: 120,
        color: const Color(0xFFE2E8F0),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8), size: 40),
        ),
      );
}

// ── 情報の1行（アイコン・ラベル・値）────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }
}

// ── タグセクション ────────────────────────────────────────
class _TagSection extends ConsumerStatefulWidget {
  final CardModel card;
  const _TagSection({required this.card});

  @override
  ConsumerState<_TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends ConsumerState<_TagSection> {
  bool _isAdding = false; // タグ追加フォームの表示フラグ
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('タグ',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569))),
            const Spacer(),
            // 「タグ追加」「キャンセル」ボタン
            TextButton.icon(
              onPressed: () => setState(() => _isAdding = !_isAdding),
              icon: Icon(_isAdding ? Icons.close : Icons.add, size: 14),
              label: Text(_isAdding ? 'キャンセル' : 'タグ追加',
                  style: const TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E40AF)),
            ),
          ],
        ),

        // タグ一覧（Wrap = 横並び・折り返し）
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: widget.card.tags
              .map((tag) =>
                  _TagChip(label: tag, onDelete: () => _removeTag(tag)))
              .toList(),
        ),

        // タグ追加フォーム（_isAddingがtrueのときだけ表示）
        if (_isAdding)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true, // フォームが開いたらキーボードを自動表示
                    decoration: const InputDecoration(
                      hintText: 'タグを入力（例: 展示会）',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (_) => _addTag(), // Enterキーでも追加できる
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addTag,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8)),
                  child: const Text('追加', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// タグを追加する
  Future<void> _addTag() async {
    final tag = _ctrl.text.trim();
    // 空 or すでに同じタグがあれば追加しない
    if (tag.isEmpty || widget.card.tags.contains(tag)) {
      _ctrl.clear();
      return;
    }
    await ref.read(updateTagsProvider(
      UpdateTagsParams(
          cardId: widget.card.id, tags: [...widget.card.tags, tag]),
    ).future);
    _ctrl.clear();
    if (mounted) setState(() => _isAdding = false);
  }

  /// タグを削除する
  Future<void> _removeTag(String tag) async {
    await ref.read(updateTagsProvider(
      UpdateTagsParams(
          cardId: widget.card.id,
          tags: widget.card.tags.where((t) => t != tag).toList()),
    ).future);
  }
}

// 削除ボタン付きタグチップ
class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  const _TagChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF16A34A))),
          const SizedBox(width: 4),
          // ✕ボタン（タップでタグ削除）
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close,
                size: 13, color: Color(0xFF86EFAC)),
          ),
        ],
      ),
    );
  }
}