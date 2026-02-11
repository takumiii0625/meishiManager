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
  /// Firestore Document ID（doc.id を詰める想定）
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get company => throw _privateConstructorUsedError;
  String get industry => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;

  /// Storageに上げた画像URL（空でもOKなら default '' にしても良い）
  String get imageUrl => throw _privateConstructorUsedError;

  /// OCRの生テキスト
  String get rawText => throw _privateConstructorUsedError;

  /// pending_industry / ready
  CardStatus get status => throw _privateConstructorUsedError;
  @TimestampDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
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
    String notes,
    String imageUrl,
    String rawText,
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
    Object? notes = null,
    Object? imageUrl = null,
    Object? rawText = null,
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
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            rawText: null == rawText
                ? _value.rawText
                : rawText // ignore: cast_nullable_to_non_nullable
                      as String,
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
    String notes,
    String imageUrl,
    String rawText,
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
    Object? notes = null,
    Object? imageUrl = null,
    Object? rawText = null,
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
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        rawText: null == rawText
            ? _value.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String,
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
    required this.name,
    required this.company,
    required this.industry,
    required this.phone,
    required this.email,
    required this.notes,
    required this.imageUrl,
    required this.rawText,
    required this.status,
    @TimestampDateTimeConverter() required this.createdAt,
    @TimestampDateTimeConverter() required this.updatedAt,
  }) : super._();

  factory _$CardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardModelImplFromJson(json);

  /// Firestore Document ID（doc.id を詰める想定）
  @override
  final String id;
  @override
  final String name;
  @override
  final String company;
  @override
  final String industry;
  @override
  final String phone;
  @override
  final String email;
  @override
  final String notes;

  /// Storageに上げた画像URL（空でもOKなら default '' にしても良い）
  @override
  final String imageUrl;

  /// OCRの生テキスト
  @override
  final String rawText;

  /// pending_industry / ready
  @override
  final CardStatus status;
  @override
  @TimestampDateTimeConverter()
  final DateTime createdAt;
  @override
  @TimestampDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'CardModel(id: $id, name: $name, company: $company, industry: $industry, phone: $phone, email: $email, notes: $notes, imageUrl: $imageUrl, rawText: $rawText, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    company,
    industry,
    phone,
    email,
    notes,
    imageUrl,
    rawText,
    status,
    createdAt,
    updatedAt,
  );

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
    required final String name,
    required final String company,
    required final String industry,
    required final String phone,
    required final String email,
    required final String notes,
    required final String imageUrl,
    required final String rawText,
    required final CardStatus status,
    @TimestampDateTimeConverter() required final DateTime createdAt,
    @TimestampDateTimeConverter() required final DateTime updatedAt,
  }) = _$CardModelImpl;
  const _CardModel._() : super._();

  factory _CardModel.fromJson(Map<String, dynamic> json) =
      _$CardModelImpl.fromJson;

  /// Firestore Document ID（doc.id を詰める想定）
  @override
  String get id;
  @override
  String get name;
  @override
  String get company;
  @override
  String get industry;
  @override
  String get phone;
  @override
  String get email;
  @override
  String get notes;

  /// Storageに上げた画像URL（空でもOKなら default '' にしても良い）
  @override
  String get imageUrl;

  /// OCRの生テキスト
  @override
  String get rawText;

  /// pending_industry / ready
  @override
  CardStatus get status;
  @override
  @TimestampDateTimeConverter()
  DateTime get createdAt;
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
