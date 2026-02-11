// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      plan: $enumDecode(_$UserPlanEnumMap, json['plan']),
      cardLimit: (json['cardLimit'] as num).toInt(),
      trialSearchRemaining: (json['trialSearchRemaining'] as num).toInt(),
      trialIndustryRemaining: (json['trialIndustryRemaining'] as num).toInt(),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'plan': _$UserPlanEnumMap[instance.plan]!,
      'cardLimit': instance.cardLimit,
      'trialSearchRemaining': instance.trialSearchRemaining,
      'trialIndustryRemaining': instance.trialIndustryRemaining,
    };

const _$UserPlanEnumMap = {UserPlan.free: 'free', UserPlan.pro: 'pro'};
