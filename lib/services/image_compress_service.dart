// ============================================================
// image_compress_service.dart
// 画像圧縮の処理をまとめたクラス
//
// 【なぜ圧縮が必要か？】
//   スマホのカメラで撮影した画像は3〜10MBになることがある。
//   そのままFirebase StorageやGeminiに送ると：
//     ・通信量が多くなる（コスト増）
//     ・送信に時間がかかる（UX悪化）
//   なので、アップロード前に圧縮してサイズを小さくする。
//
// 【2種類の圧縮を使い分ける理由】
//   ・Storage用（compressForUpload）：表示用なのでそこそこ高画質
//   ・Gemini用（compressForGemini）：文字が読めればOKなので低画質でOK
//
// 【推奨パラメータの根拠】
//   minWidth 1000px / quality 82 → 名刺の文字が読める最低解像度を保ちつつ
//   元画像3MB → 圧縮後150〜250KB 程度に削減
//   quality 75未満はOCR精度が落ちるリスクがあるため非推奨
// ============================================================

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 画像圧縮の責務をここに集約するクラス
///
/// static メソッドだけなので、インスタンス化（new）せずに使える。
/// 例: ImageCompressService.compressForUpload(path)
class ImageCompressService {
  /// Firebase Storage アップロード用圧縮
  ///
  /// [sourcePath] 圧縮前の画像ファイルパス
  /// 戻り値: 圧縮後の画像ファイル（圧縮失敗時は元ファイルをそのまま返す）
  static Future<File> compressForUpload(String sourcePath) async {
    // 一時ディレクトリ = アプリが一時的にファイルを保存できる場所
    final dir = await getTemporaryDirectory();
    // 出力ファイルのパスを生成（タイムスタンプで一意にする）
    final outPath = p.join(
      dir.path,
      'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // flutter_image_compress で圧縮して新しいファイルに保存
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,  // 入力ファイル
      outPath,     // 出力ファイル
      minWidth: 1000,  // 最小幅（これ以下に縮小しない）
      minHeight: 600,  // 最小高さ
      quality: 82,     // JPEG品質（0〜100、高いほど高画質・大きいファイル）
      format: CompressFormat.jpeg,
    );

    // 圧縮失敗時は元ファイルをそのまま返す（エラーにしない）
    if (result == null) return File(sourcePath);
    return File(result.path);
  }

  /// Gemini API 送信用圧縮（通信コスト・速度優先）
  ///
  /// Geminiはテキスト抽出が目的なので、画質よりもサイズを優先する。
  /// quality を 75 まで下げて、より小さいファイルにする。
  static Future<File> compressForGemini(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'gemini_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      outPath,
      minWidth: 800,   // Storageより小さめ
      minHeight: 500,
      quality: 75,     // Storageより低めだがOCRには十分
      format: CompressFormat.jpeg,
    );

    if (result == null) return File(sourcePath);
    return File(result.path);
  }
}
