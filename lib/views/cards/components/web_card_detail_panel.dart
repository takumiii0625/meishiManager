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
import '../../../services/mail_app_service.dart';
import 'cards_theme.dart';
import 'edit_card_dialog.dart';

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
                // 編集ボタン
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: CardsColors.primary),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => EditCardDialog(card: widget.card),
                  ),
                  tooltip: '編集',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
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
                  if (card.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('タグ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CardsColors.textSub)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: card.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF16A34A))),
                      )).toList(),
                    ),
                  ],

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
