import 'package:freezed_annotation/freezed_annotation.dart';
import 'converters/timestamp_converter.dart';

part 'card_model.freezed.dart';
part 'card_model.g.dart';

/// OCR後の状態など（仕様書: pending_industry / ready）
@JsonEnum(alwaysCreate: true)
enum CardStatus {
  @JsonValue('pending_industry')
  pendingIndustry,

  @JsonValue('ready')
  ready,
}

@freezed
class CardModel with _$CardModel {
  const CardModel._();

  const factory CardModel({
    /// Firestore Document ID（doc.id を詰める想定）
    required String id,

    required String name,
    required String company,
    required String industry,
    required String phone,
    required String email,
    required String notes,

    /// Storageに上げた画像URL（空でもOKなら default '' にしても良い）
    required String imageUrl,

    /// OCRの生テキスト
    required String rawText,

    /// pending_industry / ready
    required CardStatus status,

    @TimestampDateTimeConverter() required DateTime createdAt,
    @TimestampDateTimeConverter() required DateTime updatedAt,
  }) = _CardModel;

  factory CardModel.fromJson(Map<String, dynamic> json) => _$CardModelFromJson(json);

  /// Firestoreに保存するMap（docIdは別管理にしたいなら外す運用も可）
  Map<String, dynamic> toFirestore() => toJson();
}
