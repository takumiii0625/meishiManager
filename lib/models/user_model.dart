import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@JsonEnum(alwaysCreate: true)
enum UserPlan {
  @JsonValue('free')
  free,

  @JsonValue('pro')
  pro,
}

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required UserPlan plan,

    /// FREE_CARD_LIMIT の実値（Remote Config等でもOK）
    required int cardLimit,

    /// 無料試用の残り回数（検索）
    required int trialSearchRemaining,

    /// 無料試用の残り回数（業種推定）
    required int trialIndustryRemaining,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toFirestore() => toJson();
}
