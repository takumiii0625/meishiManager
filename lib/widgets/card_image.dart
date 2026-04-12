// ============================================================
// card_image.dart
// 名刺画像を表示する共通ウィジェット
//
// 【なぜこのウィジェットを作るか？】
//   一覧・詳細・検索の3箇所で Image.network() を使っていたが、
//   以下の問題があった：
//     ① ダウンロード中は真っ白になる（loadingBuilder がない）
//     ② 一度表示した画像でも画面を離れると再ダウンロードする
//
//   このウィジェットでは cached_network_image パッケージを使い：
//     ① ダウンロード中はシマーアニメーション（グレーの点滅）を表示
//     ② 端末のディスクにキャッシュして次回から即表示
//   の2つを解決する。
//
// 【使い方】
//   // 一覧のサムネイル（小さいサイズ）
//   CardImage(url: card.displayImageUrl, width: 56, height: 34)
//
//   // 詳細画面（大きいサイズ・縦横比維持）
//   CardImage(url: card.frontImageUrl, fit: BoxFit.contain, height: 280)
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CardImage extends StatelessWidget {
  /// 表示する Firebase Storage の画像URL
  /// 空文字や null の場合はプレースホルダーを表示する
  final String? url;

  /// 画像の表示サイズ（省略可）
  final double? width;
  final double? height;

  /// 画像のフィット方法
  /// 一覧: BoxFit.cover（枠いっぱいに拡大）
  /// 詳細: BoxFit.contain（縦横比を保って収める）
  final BoxFit fit;

  /// 画像がない場合に表示するアイコン（省略時は person アイコン）
  final IconData placeholderIcon;

  /// プレースホルダーのアイコンサイズ
  final double iconSize;

  const CardImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.person,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    // URLが空の場合はプレースホルダーを表示
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,

      // ── ダウンロード中の表示 ─────────────────────────
      // シマーアニメーション = グレーがゆっくり明滅する表示
      // 「読み込み中」がわかるのでユーザーが戸惑わない
      placeholder: (context, url) => _ShimmerBox(width: width, height: height),

      // ── 読み込みエラー時の表示 ───────────────────────
      // ネットワークエラーや URL が無効な場合
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE2E8F0),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: const Color(0xFF94A3B8),
            size: iconSize,
          ),
        ),
      ),
    );
  }

  // 画像なしのプレースホルダー
  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFDBEAFE),
      child: Center(
        child: Icon(
          placeholderIcon,
          color: const Color(0xFF93C5FD),
          size: iconSize,
        ),
      ),
    );
  }
}

// ── シマーアニメーションウィジェット ─────────────────────
// グレーの背景がゆっくり明滅してローディング中であることを示す。
// 外部パッケージ（shimmer等）を使わず AnimationController で実装。
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  const _ShimmerBox({this.width, this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 0.9秒かけて明→暗→明を繰り返す
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        color: Color.lerp(
          const Color(0xFFE2E8F0), // 薄いグレー
          const Color(0xFFCBD5E1), // やや濃いグレー
          _animation.value,
        ),
      ),
    );
  }
}
