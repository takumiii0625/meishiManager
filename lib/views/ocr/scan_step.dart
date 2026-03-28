// ============================================================
// scan_step.dart
// 撮影フローで使うデータクラスを定義するファイル
//
// 【役割】
//   MultiScanPage（撮影画面）で撮影した結果を保持するクラスと、
//   撮影の進行状態を表すenumを定義する。
// ============================================================

/// スキャンの進行ステップを表すenum
///
/// enum（列挙型）= あらかじめ決まった値の中から1つを選ぶ型
/// 例: ScanStep.front → 今は表面撮影中
enum ScanStep {
  front,   // 表面を撮影中
  askBack, // 「裏面を撮影しますか？」を表示中
  back,    // 裏面を撮影中
}

/// 1枚の名刺の撮影結果（表＋裏のパス）
///
/// MultiScanPage → BatchAnalyzePage の間でデータを渡すために使う。
/// frontImagePath = 端末内の一時ファイルパス（例: /tmp/front_12345.jpg）
/// backImagePath  = 裏面を撮影しなかった場合は null
class CardScanResult {
  final String frontImagePath; // 表面の画像ファイルパス（必須）
  final String? backImagePath; // 裏面のファイルパス（省略可。nullなら裏面なし）

  // const コンストラクタ = コンパイル時に値が確定する（パフォーマンスが良い）
  const CardScanResult({
    required this.frontImagePath,
    this.backImagePath,
  });
}
