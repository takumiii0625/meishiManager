// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CardModel _$CardModelFromJson(Map<String, dynamic> json) {
  return _CardModel.fromJson(json);
}

/// @nodoc
mixin _$CardModel {
  /// FirestoreのドキュメントID（自動生成される一意なID）
  String get id =>
      throw _privateConstructorUsedError; // ── 基本情報 ──────────────────────────────────
  String get name => throw _privateConstructorUsedError; // 氏名
  String get company => throw _privateConstructorUsedError; // 会社名
  String get industry => throw _privateConstructorUsedError; // 業種（Geminiが自動推定）
  String get phone => throw _privateConstructorUsedError; // 電話番号
  String get email => throw _privateConstructorUsedError; // メールアドレス
  String get address => throw _privateConstructorUsedError; // 住所
  String get notes => throw _privateConstructorUsedError; // メモ（ユーザーが手入力）
  String get rawText =>
      throw _privateConstructorUsedError; // OCRで読み取った生テキスト（内部用）
  // ── 所属情報 ──────────────────────────────────
  // 部署＞役職の優先度で表示・フィルターに使う
  // 例: 「営業部」「技術部」「経営企画室」
  String get department => throw _privateConstructorUsedError; // 部署名（Geminiが抽出）
  // 例: 「部長」「代表取締役」「営業担当」
  // 役職がない名刺でも部署があれば所属がわかる
  String get jobLevel =>
      throw _privateConstructorUsedError; // 役職（Geminiが抽出・正規化しない）
  // ── 画像URL ───────────────────────────────────
  // Firebase StorageにアップロードされたダウンロードURLが入る
  String get frontImageUrl => throw _privateConstructorUsedError; // 表面の画像URL
  String get backImageUrl =>
      throw _privateConstructorUsedError; // 裏面の画像URL（撮影しなければ空）
  // ── フィルター・絞り込み用フィールド ─────────
  // Geminiが住所から都道府県を抽出して保存（例: "東京都"）
  String get prefecture =>
      throw _privateConstructorUsedError; // ユーザーが自由に付けるタグ（例: ["展示会", "重要"]）
  List<String> get tags =>
      throw _privateConstructorUsedError; // Geminiが推定した業種の候補リスト（例: ["IT・ソフトウェア", "通信"]）
  List<String> get industryCandidates =>
      throw _privateConstructorUsedError; // ── 論理削除フィールド ────────────────────────
  // 論理削除 = 実際には消さず「削除済みフラグ」を立てる方式
  //   isDeleted: true  → ゴミ箱に入っている状態
  //   isDeleted: false → 通常表示される状態
  bool get isDeleted => throw _privateConstructorUsedError;
  @TimestampDateTimeConverter()
  DateTime? get deletedAt => throw _privateConstructorUsedError; // ゴミ箱に入れた日時
  // ── ステータス・タイムスタンプ ────────────────
  CardStatus get status => throw _privateConstructorUsedError;
  @TimestampDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError; // 登録日時
  @TimestampDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CardModelCopyWith<CardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CardModelCopyWith<$Res> {
  factory $CardModelCopyWith(CardModel value, $Res Function(CardModel) then) =
      _$CardModelCopyWithImpl<$Res, CardModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String company,
    String industry,
    String phone,
    String email,
    String address,
    String notes,
    String rawText,
    String department,
    String jobLevel,
    String frontImageUrl,
    String backImageUrl,
    String prefecture,
    List<String> tags,
    List<String> industryCandidates,
    bool isDeleted,
    @TimestampDateTimeConverter() DateTime? deletedAt,
    CardStatus status,
    @TimestampDateTimeConverter() DateTime createdAt,
    @TimestampDateTimeConverter() DateTime updatedAt,
  });
}

/// @nodoc
class _$CardModelCopyWithImpl<$Res, $Val extends CardModel>
    implements $CardModelCopyWith<$Res> {
  _$CardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? company = null,
    Object? industry = null,
    Object? phone = null,
    Object? email = null,
    Object? address = null,
    Object? notes = null,
    Object? rawText = null,
    Object? department = null,
    Object? jobLevel = null,
    Object? frontImageUrl = null,
    Object? backImageUrl = null,
    Object? prefecture = null,
    Object? tags = null,
    Object? industryCandidates = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            company: null == company
                ? _value.company
                : company // ignore: cast_nullable_to_non_nullable
                      as String,
            industry: null == industry
                ? _value.industry
                : industry // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String,
            rawText: null == rawText
                ? _value.rawText
                : rawText // ignore: cast_nullable_to_non_nullable
                      as String,
            department: null == department
                ? _value.department
                : department // ignore: cast_nullable_to_non_nullable
                      as String,
            jobLevel: null == jobLevel
                ? _value.jobLevel
                : jobLevel // ignore: cast_nullable_to_non_nullable
                      as String,
            frontImageUrl: null == frontImageUrl
                ? _value.frontImageUrl
                : frontImageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            backImageUrl: null == backImageUrl
                ? _value.backImageUrl
                : backImageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            prefecture: null == prefecture
                ? _value.prefecture
                : prefecture // ignore: cast_nullable_to_non_nullable
                      as String,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            industryCandidates: null == industryCandidates
                ? _value.industryCandidates
                : industryCandidates // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as CardStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CardModelImplCopyWith<$Res>
    implements $CardModelCopyWith<$Res> {
  factory _$$CardModelImplCopyWith(
    _$CardModelImpl value,
    $Res Function(_$CardModelImpl) then,
  ) = __$$CardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String company,
    String industry,
    String phone,
    String email,
    String address,
    String notes,
    String rawText,
    String department,
    String jobLevel,
    String frontImageUrl,
    String backImageUrl,
    String prefecture,
    List<String> tags,
    List<String> industryCandidates,
    bool isDeleted,
    @TimestampDateTimeConverter() DateTime? deletedAt,
    CardStatus status,
    @TimestampDateTimeConverter() DateTime createdAt,
    @TimestampDateTimeConverter() DateTime updatedAt,
  });
}

/// @nodoc
class __$$CardModelImplCopyWithImpl<$Res>
    extends _$CardModelCopyWithImpl<$Res, _$CardModelImpl>
    implements _$$CardModelImplCopyWith<$Res> {
  __$$CardModelImplCopyWithImpl(
    _$CardModelImpl _value,
    $Res Function(_$CardModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? company = null,
    Object? industry = null,
    Object? phone = null,
    Object? email = null,
    Object? address = null,
    Object? notes = null,
    Object? rawText = null,
    Object? department = null,
    Object? jobLevel = null,
    Object? frontImageUrl = null,
    Object? backImageUrl = null,
    Object? prefecture = null,
    Object? tags = null,
    Object? industryCandidates = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$CardModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        company: null == company
            ? _value.company
            : company // ignore: cast_nullable_to_non_nullable
                  as String,
        industry: null == industry
            ? _value.industry
            : industry // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        rawText: null == rawText
            ? _value.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String,
        department: null == department
            ? _value.department
            : department // ignore: cast_nullable_to_non_nullable
                  as String,
        jobLevel: null == jobLevel
            ? _value.jobLevel
            : jobLevel // ignore: cast_nullable_to_non_nullable
                  as String,
        frontImageUrl: null == frontImageUrl
            ? _value.frontImageUrl
            : frontImageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        backImageUrl: null == backImageUrl
            ? _value.backImageUrl
            : backImageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        prefecture: null == prefecture
            ? _value.prefecture
            : prefecture // ignore: cast_nullable_to_non_nullable
                  as String,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        industryCandidates: null == industryCandidates
            ? _value._industryCandidates
            : industryCandidates // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as CardStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CardModelImpl extends _CardModel {
  const _$CardModelImpl({
    required this.id,
    this.name = '',
    this.company = '',
    this.industry = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.rawText = '',
    this.department = '',
    this.jobLevel = '',
    this.frontImageUrl = '',
    this.backImageUrl = '',
    this.prefecture = '',
    final List<String> tags = const [],
    final List<String> industryCandidates = const [],
    this.isDeleted = false,
    @TimestampDateTimeConverter() this.deletedAt,
    this.status = CardStatus.pendingIndustry,
    @TimestampDateTimeConverter() required this.createdAt,
    @TimestampDateTimeConverter() required this.updatedAt,
  }) : _tags = tags,
       _industryCandidates = industryCandidates,
       super._();

  factory _$CardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardModelImplFromJson(json);

  /// FirestoreのドキュメントID（自動生成される一意なID）
  @override
  final String id;
  // ── 基本情報 ──────────────────────────────────
  @override
  @JsonKey()
  final String name;
  // 氏名
  @override
  @JsonKey()
  final String company;
  // 会社名
  @override
  @JsonKey()
  final String industry;
  // 業種（Geminiが自動推定）
  @override
  @JsonKey()
  final String phone;
  // 電話番号
  @override
  @JsonKey()
  final String email;
  // メールアドレス
  @override
  @JsonKey()
  final String address;
  // 住所
  @override
  @JsonKey()
  final String notes;
  // メモ（ユーザーが手入力）
  @override
  @JsonKey()
  final String rawText;
  // OCRで読み取った生テキスト（内部用）
  // ── 所属情報 ──────────────────────────────────
  // 部署＞役職の優先度で表示・フィルターに使う
  // 例: 「営業部」「技術部」「経営企画室」
  @override
  @JsonKey()
  final String department;
  // 部署名（Geminiが抽出）
  // 例: 「部長」「代表取締役」「営業担当」
  // 役職がない名刺でも部署があれば所属がわかる
  @override
  @JsonKey()
  final String jobLevel;
  // 役職（Geminiが抽出・正規化しない）
  // ── 画像URL ───────────────────────────────────
  // Firebase StorageにアップロードされたダウンロードURLが入る
  @override
  @JsonKey()
  final String frontImageUrl;
  // 表面の画像URL
  @override
  @JsonKey()
  final String backImageUrl;
  // 裏面の画像URL（撮影しなければ空）
  // ── フィルター・絞り込み用フィールド ─────────
  // Geminiが住所から都道府県を抽出して保存（例: "東京都"）
  @override
  @JsonKey()
  final String prefecture;
  // ユーザーが自由に付けるタグ（例: ["展示会", "重要"]）
  final List<String> _tags;
  // ユーザーが自由に付けるタグ（例: ["展示会", "重要"]）
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  // Geminiが推定した業種の候補リスト（例: ["IT・ソフトウェア", "通信"]）
  final List<String> _industryCandidates;
  // Geminiが推定した業種の候補リスト（例: ["IT・ソフトウェア", "通信"]）
  @override
  @JsonKey()
  List<String> get industryCandidates {
    if (_industryCandidates is EqualUnmodifiableListView)
      return _industryCandidates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_industryCandidates);
  }

  // ── 論理削除フィールド ────────────────────────
  // 論理削除 = 実際には消さず「削除済みフラグ」を立てる方式
  //   isDeleted: true  → ゴミ箱に入っている状態
  //   isDeleted: false → 通常表示される状態
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  @TimestampDateTimeConverter()
  final DateTime? deletedAt;
  // ゴミ箱に入れた日時
  // ── ステータス・タイムスタンプ ────────────────
  @override
  @JsonKey()
  final CardStatus status;
  @override
  @TimestampDateTimeConverter()
  final DateTime createdAt;
  // 登録日時
  @override
  @TimestampDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'CardModel(id: $id, name: $name, company: $company, industry: $industry, phone: $phone, email: $email, address: $address, notes: $notes, rawText: $rawText, department: $department, jobLevel: $jobLevel, frontImageUrl: $frontImageUrl, backImageUrl: $backImageUrl, prefecture: $prefecture, tags: $tags, industryCandidates: $industryCandidates, isDeleted: $isDeleted, deletedAt: $deletedAt, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.company, company) || other.company == company) &&
            (identical(other.industry, industry) ||
                other.industry == industry) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.jobLevel, jobLevel) ||
                other.jobLevel == jobLevel) &&
            (identical(other.frontImageUrl, frontImageUrl) ||
                other.frontImageUrl == frontImageUrl) &&
            (identical(other.backImageUrl, backImageUrl) ||
                other.backImageUrl == backImageUrl) &&
            (identical(other.prefecture, prefecture) ||
                other.prefecture == prefecture) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(
              other._industryCandidates,
              _industryCandidates,
            ) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    company,
    industry,
    phone,
    email,
    address,
    notes,
    rawText,
    department,
    jobLevel,
    frontImageUrl,
    backImageUrl,
    prefecture,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_industryCandidates),
    isDeleted,
    deletedAt,
    status,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of CardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardModelImplCopyWith<_$CardModelImpl> get copyWith =>
      __$$CardModelImplCopyWithImpl<_$CardModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CardModelImplToJson(this);
  }
}

abstract class _CardModel extends CardModel {
  const factory _CardModel({
    required final String id,
    final String name,
    final String company,
    final String industry,
    final String phone,
    final String email,
    final String address,
    final String notes,
    final String rawText,
    final String department,
    final String jobLevel,
    final String frontImageUrl,
    final String backImageUrl,
    final String prefecture,
    final List<String> tags,
    final List<String> industryCandidates,
    final bool isDeleted,
    @TimestampDateTimeConverter() final DateTime? deletedAt,
    final CardStatus status,
    @TimestampDateTimeConverter() required final DateTime createdAt,
    @TimestampDateTimeConverter() required final DateTime updatedAt,
  }) = _$CardModelImpl;
  const _CardModel._() : super._();

  factory _CardModel.fromJson(Map<String, dynamic> json) =
      _$CardModelImpl.fromJson;

  /// FirestoreのドキュメントID（自動生成される一意なID）
  @override
  String get id; // ── 基本情報 ──────────────────────────────────
  @override
  String get name; // 氏名
  @override
  String get company; // 会社名
  @override
  String get industry; // 業種（Geminiが自動推定）
  @override
  String get phone; // 電話番号
  @override
  String get email; // メールアドレス
  @override
  String get address; // 住所
  @override
  String get notes; // メモ（ユーザーが手入力）
  @override
  String get rawText; // OCRで読み取った生テキスト（内部用）
  // ── 所属情報 ──────────────────────────────────
  // 部署＞役職の優先度で表示・フィルターに使う
  // 例: 「営業部」「技術部」「経営企画室」
  @override
  String get department; // 部署名（Geminiが抽出）
  // 例: 「部長」「代表取締役」「営業担当」
  // 役職がない名刺でも部署があれば所属がわかる
  @override
  String get jobLevel; // 役職（Geminiが抽出・正規化しない）
  // ── 画像URL ───────────────────────────────────
  // Firebase StorageにアップロードされたダウンロードURLが入る
  @override
  String get frontImageUrl; // 表面の画像URL
  @override
  String get backImageUrl; // 裏面の画像URL（撮影しなければ空）
  // ── フィルター・絞り込み用フィールド ─────────
  // Geminiが住所から都道府県を抽出して保存（例: "東京都"）
  @override
  String get prefecture; // ユーザーが自由に付けるタグ（例: ["展示会", "重要"]）
  @override
  List<String> get tags; // Geminiが推定した業種の候補リスト（例: ["IT・ソフトウェア", "通信"]）
  @override
  List<String> get industryCandidates; // ── 論理削除フィールド ────────────────────────
  // 論理削除 = 実際には消さず「削除済みフラグ」を立てる方式
  //   isDeleted: true  → ゴミ箱に入っている状態
  //   isDeleted: false → 通常表示される状態
  @override
  bool get isDeleted;
  @override
  @TimestampDateTimeConverter()
  DateTime? get deletedAt; // ゴミ箱に入れた日時
  // ── ステータス・タイムスタンプ ────────────────
  @override
  CardStatus get status;
  @override
  @TimestampDateTimeConverter()
  DateTime get createdAt; // 登録日時
  @override
  @TimestampDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of CardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardModelImplCopyWith<_$CardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
