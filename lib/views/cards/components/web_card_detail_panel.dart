// ============================================================
// web_card_detail_panel.dart
// Web版 名刺詳細パネル
//
// 【役割】
//   一覧画面の右側に表示するスライドパネル。
//   名刺の全情報（画像・氏名・会社・連絡先・タグ・メモ）を表示する。
//
// 【使い方】
//   WebCardsPage で selectedCard が非 null になったときに表示される。
//   閉じるボタンまたは一覧の別行をクリックで切り替え。
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/card_model.dart';
import '../../../providers/card_providers.dart';
import '../../../services/mail_app_service.dart';
import 'cards_theme.dart';

class WebCardDetailPanel extends ConsumerStatefulWidget {
  final CardModel card;
  final VoidCallback onClose;

  const WebCardDetailPanel({
    super.key,
    required this.card,
    required this.onClose,
  });

  @override
  ConsumerState<WebCardDetailPanel> createState() => _WebCardDetailPanelState();
}

class _WebCardDetailPanelState extends ConsumerState<WebCardDetailPanel> {
  bool _showFront = true; // 表面/裏面の切り替え

  @override
  void didUpdateWidget(WebCardDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // カードが切り替わったら表面に戻す
    if (oldWidget.card.id != widget.card.id) {
      _showFront = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final hasFront = card.frontImageUrl.isNotEmpty;
    final hasBack  = card.backImageUrl.isNotEmpty;
    final imageUrl = _showFront ? card.frontImageUrl : card.backImageUrl;

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: CardsColors.border)),
      ),
      child: Column(
        children: [
          // ── パネルヘッダー ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: CardsColors.border)),
            ),
            child: Row(
              children: [
                const Text(
                  '名刺詳細',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CardsColors.textMain,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: CardsColors.textMid),
                  onPressed: widget.onClose,
                  tooltip: '閉じる',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── スクロール可能なコンテンツ ───────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 名刺画像 ──────────────────────────────
                  if (hasFront || hasBack) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        color: const Color(0xFFF1F5F9),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.contain,
                                // ローディング中はグレーのインジケーターを表示
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: CardsColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: CardsColors.textSub, size: 32),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    color: CardsColors.textSub, size: 32),
                              ),
                      ),
                    ),
                    // 表面/裏面切り替えボタン（両方ある場合のみ）
                    if (hasFront && hasBack)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _toggleBtn('表面', _showFront, () => setState(() => _showFront = true)),
                            const SizedBox(width: 8),
                            _toggleBtn('裏面', !_showFront, () => setState(() => _showFront = false)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // ── 氏名・会社・所属 ──────────────────────
                  Text(
                    card.name.isNotEmpty ? card.name : '（名前なし）',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: CardsColors.textMain,
                    ),
                  ),
                  if (card.company.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      card.company,
                      style: const TextStyle(
                          fontSize: 14, color: CardsColors.textMid),
                    ),
                  ],
                  if (card.affiliationText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      card.affiliationText,
                      style: const TextStyle(
                          fontSize: 12, color: CardsColors.textSub),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: CardsColors.border),
                  const SizedBox(height: 12),

                  // ── 詳細情報 ──────────────────────────────
                  if (card.industry.isNotEmpty)
                    _infoRow(Icons.business_outlined, '業種', card.industry),
                  if (card.prefecture.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, '地域', card.prefecture),
                  if (card.phone.isNotEmpty)
                    _tappableRow(
                      Icons.phone_outlined,
                      '電話',
                      card.phone,
                      color: CardsColors.primary,
                      onTap: () => _launchPhone(card.phone),
                    ),
                  if (card.email.isNotEmpty)
                    _tappableRow(
                      Icons.email_outlined,
                      'メール',
                      card.email,
                      color: CardsColors.primary,
                      onTap: () => _launchEmail(card.email),
                    ),
                  if (card.address.isNotEmpty)
                    _infoRow(Icons.map_outlined, '住所', card.address),
                  if (card.notes.isNotEmpty)
                    _infoRow(Icons.notes, 'メモ', card.notes),

                  // ── タグ ──────────────────────────────────
                  const SizedBox(height: 8),
                  _TagSection(card: card),

                  // ── 登録日 ────────────────────────────────
                  const SizedBox(height: 16),
                  const Divider(color: CardsColors.border),
                  const SizedBox(height: 8),
                  Text(
                    '登録日: ${card.createdAt.year}年${card.createdAt.month}月${card.createdAt.day}日',
                    style: const TextStyle(
                        fontSize: 11, color: CardsColors.textSub),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 表面/裏面トグルボタン
  Widget _toggleBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CardsColors.primary : Colors.white,
          border: Border.all(
              color: isSelected ? CardsColors.primary : CardsColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : CardsColors.textMid,
          ),
        ),
      ),
    );
  }

  // 通常の情報行
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CardsColors.textSub),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: CardsColors.textSub)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: CardsColors.textMain)),
          ),
        ],
      ),
    );
  }

  // タップ可能な情報行（電話・メール）
  Widget _tappableRow(
    IconData icon,
    String label,
    String value, {
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: CardsColors.textSub),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: CardsColors.textSub)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 電話発信
  Future<void> _launchPhone(String phone) async {
    final cleaned = phone.split(RegExp(r'[/,・\n]')).first.trim()
        .replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // メール起動（設定済みアプリを使う）
  Future<void> _launchEmail(String email) async {
    final address = email.split(RegExp(r'[/,・\n]')).first.trim();
    // 設定画面で選択したメールアプリを使う
    final app = ref.read(selectedMailAppProvider).maybeWhen(
      data: (a) => a,
      orElse: () => kWebMailApps.first,
    );
    final uri = app.composeUri(address);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // フォールバック：mailto:
      final fallback = Uri(scheme: 'mailto', path: address);
      if (await canLaunchUrl(fallback)) await launchUrl(fallback);
    }
  }
}

// ================================================================
// タグ編集セクション
// ================================================================
class _TagSection extends ConsumerStatefulWidget {
  final CardModel card;
  const _TagSection({required this.card});

  @override
  ConsumerState<_TagSection> createState() => _TagSectionState();
}

class _TagSectionState extends ConsumerState<_TagSection> {
  bool _isAdding = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addTag(List<String> currentTags) async {
    final tag = _ctrl.text.trim();
    if (tag.isEmpty || currentTags.contains(tag)) {
      _ctrl.clear();
      return;
    }
    await ref.read(updateTagsProvider(
      UpdateTagsParams(
          cardId: widget.card.id,
          tags: [...currentTags, tag]),
    ).future);
    _ctrl.clear();
    if (mounted) setState(() => _isAdding = false);
  }

  Future<void> _removeTag(List<String> currentTags, String tag) async {
    await ref.read(updateTagsProvider(
      UpdateTagsParams(
          cardId: widget.card.id,
          tags: currentTags.where((t) => t != tag).toList()),
    ).future);
  }

  @override
  Widget build(BuildContext context) {
    // カードをリアルタイム監視 → タグ更新が即時反映される
    final cardAsync = ref.watch(cardStreamProvider(widget.card.id));
    final tags = cardAsync.valueOrNull?.tags ?? widget.card.tags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ヘッダー ──
        Row(
          children: [
            const Text('タグ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CardsColors.textSub)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _isAdding = !_isAdding),
              child: Row(
                children: [
                  Icon(
                    _isAdding ? Icons.close : Icons.add,
                    size: 13,
                    color: CardsColors.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _isAdding ? 'キャンセル' : 'タグ追加',
                    style: const TextStyle(
                        fontSize: 11, color: CardsColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── タグ一覧 ──
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CardsColors.primaryLight,
                border: Border.all(
                    color: CardsColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tag,
                      style: const TextStyle(
                          fontSize: 11,
                          color: CardsColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _removeTag(tags, tag),
                    child: const Icon(Icons.close,
                        size: 11, color: CardsColors.primary),
                  ),
                ],
              ),
            )).toList(),
          ),

        // ── タグ入力フォーム ──
        if (_isAdding) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 12, color: CardsColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'タグを入力（例: 展示会）',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: CardsColors.textSub),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: CardsColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: CardsColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: CardsColors.primary)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _addTag(tags),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => _addTag(tags),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CardsColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                child: const Text('追加',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
