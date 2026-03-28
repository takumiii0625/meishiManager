// ============================================================
// card_model.dart
// 名刺1枚分のデータ構造を定義するファイル
//
// 【Freezedとは？】
//   データクラスを自動生成するライブラリ。
//   copyWith（一部だけ変えたコピーを作る）や
//   fromJson/toJson（JSONとの相互変換）が自動で使えるようになる。
//
// 【このファイルを変更したら必ずやること】
//   flutter pub run build_runner build --delete-conflicting-outputs
//   ↑ .freezed.dart と .g.dart を再生成するコマンド
// ============================================================

import 'package:freezed_annotation/freezed_annotation.dart';
import 'converters/timestamp_converter.dart';

// Freezedが自動生成するファイルを読み込む宣言
part 'card_model.freezed.dart';
part 'card_model.g.dart';

/// 名刺の処理状態を表す列挙型（enum）
/// pendingIndustry = Gemini解析待ち
/// ready           = 解析完了・一覧表示OK
@JsonEnum(alwaysCreate: true)
enum CardStatus {
  @JsonValue('pending_industry')
  pendingIndustry, // 業種推定待ち

  @JsonValue('ready')
  ready, // 完了（一覧に表示される状態）
}

/// 名刺1枚分のデータモデル
///
/// @Default('') → Firestoreにそのフィールドがなくても空文字で補完する
/// required     → 必ず値が必要（ないとエラー）
@freezed
class CardModel with _$CardModel {
  // カスタムゲッター（displayImageUrl）を追加するために必要な宣言
  const CardModel._();

  const factory CardModel({
    /// FirestoreのドキュメントID（自動生成される一意なID）
    required String id,

    // ── 基本情報 ──────────────────────────────────
    @Default('') String name,       // 氏名
    @Default('') String company,    // 会社名
    @Default('') String industry,   // 業種（Geminiが自動推定）
    @Default('') String phone,      // 電話番号
    @Default('') String email,      // メールアドレス
    @Default('') String address,    // 住所
    @Default('') String notes,      // メモ（ユーザーが手入力）
    @Default('') String rawText,    // OCRで読み取った生テキスト（内部用）

    // ── 所属情報 ──────────────────────────────────
    // 部署＞役職の優先度で表示・フィルターに使う
    // 例: 「営業部」「技術部」「経営企画室」
    @Default('') String department, // 部署名（Geminiが抽出）

    // 例: 「部長」「代表取締役」「営業担当」
    // 役職がない名刺でも部署があれば所属がわかる
    @Default('') String jobLevel,   // 役職（Geminiが抽出・正規化しない）

    // ── 画像URL ───────────────────────────────────
    // Firebase StorageにアップロードされたダウンロードURLが入る
    @Default('') String frontImageUrl, // 表面の画像URL
    @Default('') String backImageUrl,  // 裏面の画像URL（撮影しなければ空）

    // ── フィルター・絞り込み用フィールド ─────────
    // Geminiが住所から都道府県を抽出して保存（例: "東京都"）
    @Default('') String prefecture,

    // ユーザーが自由に付けるタグ（例: ["展示会", "重要"]）
    @Default([]) List<String> tags,

    // Geminiが推定した業種の候補リスト（例: ["IT・ソフトウェア", "通信"]）
    @Default([]) List<String> industryCandidates,

    // ── 論理削除フィールド ────────────────────────
    // 論理削除 = 実際には消さず「削除済みフラグ」を立てる方式
    //   isDeleted: true  → ゴミ箱に入っている状態
    //   isDeleted: false → 通常表示される状態
    @Default(false) bool isDeleted,
    @TimestampDateTimeConverter() DateTime? deletedAt, // ゴミ箱に入れた日時

    // ── ステータス・タイムスタンプ ────────────────
    @Default(CardStatus.pendingIndustry) CardStatus status,
    @TimestampDateTimeConverter() required DateTime createdAt, // 登録日時
    @TimestampDateTimeConverter() required DateTime updatedAt, // 最終更新日時
  }) = _CardModel;

  /// FirestoreのJSONデータ → CardModel に変換するファクトリ
  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);

  /// CardModel → Firestoreに保存するMapに変換
  Map<String, dynamic> toFirestore() => toJson();

  /// 表示用画像URL
  /// 表面があれば表面を、なければ裏面を返す
  String get displayImageUrl =>
      frontImageUrl.isNotEmpty ? frontImageUrl : backImageUrl;

  /// 所属表示用テキスト（部署＞役職の優先度）
  /// 例: 部署あり・役職あり → "営業部 / 部長"
  ///     部署あり・役職なし → "営業部"
  ///     部署なし・役職あり → "部長"
  ///     どちらもなし      → ""
  String get affiliationText {
    final parts = <String>[
      if (department.isNotEmpty) department,
      if (jobLevel.isNotEmpty) jobLevel,
    ];
    return parts.join(' / ');
  }
}
