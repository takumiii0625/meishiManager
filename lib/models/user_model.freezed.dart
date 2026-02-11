// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  UserPlan get plan => throw _privateConstructorUsedError;

  /// FREE_CARD_LIMIT の実値（Remote Config等でもOK）
  int get cardLimit => throw _privateConstructorUsedError;

  /// 無料試用の残り回数（検索）
  int get trialSearchRemaining => throw _privateConstructorUsedError;

  /// 無料試用の残り回数（業種推定）
  int get trialIndustryRemaining => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    UserPlan plan,
    int cardLimit,
    int trialSearchRemaining,
    int trialIndustryRemaining,
  });
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? cardLimit = null,
    Object? trialSearchRemaining = null,
    Object? trialIndustryRemaining = null,
  }) {
    return _then(
      _value.copyWith(
            plan: null == plan
                ? _value.plan
                : plan // ignore: cast_nullable_to_non_nullable
                      as UserPlan,
            cardLimit: null == cardLimit
                ? _value.cardLimit
                : cardLimit // ignore: cast_nullable_to_non_nullable
                      as int,
            trialSearchRemaining: null == trialSearchRemaining
                ? _value.trialSearchRemaining
                : trialSearchRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
            trialIndustryRemaining: null == trialIndustryRemaining
                ? _value.trialIndustryRemaining
                : trialIndustryRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    UserPlan plan,
    int cardLimit,
    int trialSearchRemaining,
    int trialIndustryRemaining,
  });
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? cardLimit = null,
    Object? trialSearchRemaining = null,
    Object? trialIndustryRemaining = null,
  }) {
    return _then(
      _$UserModelImpl(
        plan: null == plan
            ? _value.plan
            : plan // ignore: cast_nullable_to_non_nullable
                  as UserPlan,
        cardLimit: null == cardLimit
            ? _value.cardLimit
            : cardLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        trialSearchRemaining: null == trialSearchRemaining
            ? _value.trialSearchRemaining
            : trialSearchRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
        trialIndustryRemaining: null == trialIndustryRemaining
            ? _value.trialIndustryRemaining
            : trialIndustryRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl extends _UserModel {
  const _$UserModelImpl({
    required this.plan,
    required this.cardLimit,
    required this.trialSearchRemaining,
    required this.trialIndustryRemaining,
  }) : super._();

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final UserPlan plan;

  /// FREE_CARD_LIMIT の実値（Remote Config等でもOK）
  @override
  final int cardLimit;

  /// 無料試用の残り回数（検索）
  @override
  final int trialSearchRemaining;

  /// 無料試用の残り回数（業種推定）
  @override
  final int trialIndustryRemaining;

  @override
  String toString() {
    return 'UserModel(plan: $plan, cardLimit: $cardLimit, trialSearchRemaining: $trialSearchRemaining, trialIndustryRemaining: $trialIndustryRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.cardLimit, cardLimit) ||
                other.cardLimit == cardLimit) &&
            (identical(other.trialSearchRemaining, trialSearchRemaining) ||
                other.trialSearchRemaining == trialSearchRemaining) &&
            (identical(other.trialIndustryRemaining, trialIndustryRemaining) ||
                other.trialIndustryRemaining == trialIndustryRemaining));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    plan,
    cardLimit,
    trialSearchRemaining,
    trialIndustryRemaining,
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel extends UserModel {
  const factory _UserModel({
    required final UserPlan plan,
    required final int cardLimit,
    required final int trialSearchRemaining,
    required final int trialIndustryRemaining,
  }) = _$UserModelImpl;
  const _UserModel._() : super._();

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  UserPlan get plan;

  /// FREE_CARD_LIMIT の実値（Remote Config等でもOK）
  @override
  int get cardLimit;

  /// 無料試用の残り回数（検索）
  @override
  int get trialSearchRemaining;

  /// 無料試用の残り回数（業種推定）
  @override
  int get trialIndustryRemaining;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
