// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CardModelImpl _$$CardModelImplFromJson(Map<String, dynamic> json) =>
    _$CardModelImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      company: json['company'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      rawText: json['rawText'] as String? ?? '',
      department: json['department'] as String? ?? '',
      jobLevel: json['jobLevel'] as String? ?? '',
      frontImageUrl: json['frontImageUrl'] as String? ?? '',
      backImageUrl: json['backImageUrl'] as String? ?? '',
      prefecture: json['prefecture'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      industryCandidates:
          (json['industryCandidates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: const TimestampDateTimeConverter().fromJson(json['deletedAt']),
      status:
          $enumDecodeNullable(_$CardStatusEnumMap, json['status']) ??
          CardStatus.pendingIndustry,
      createdAt: const TimestampDateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampDateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$CardModelImplToJson(
  _$CardModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'company': instance.company,
  'industry': instance.industry,
  'phone': instance.phone,
  'email': instance.email,
  'address': instance.address,
  'notes': instance.notes,
  'rawText': instance.rawText,
  'department': instance.department,
  'jobLevel': instance.jobLevel,
  'frontImageUrl': instance.frontImageUrl,
  'backImageUrl': instance.backImageUrl,
  'prefecture': instance.prefecture,
  'tags': instance.tags,
  'industryCandidates': instance.industryCandidates,
  'isDeleted': instance.isDeleted,
  'deletedAt': _$JsonConverterToJson<Object?, DateTime>(
    instance.deletedAt,
    const TimestampDateTimeConverter().toJson,
  ),
  'status': _$CardStatusEnumMap[instance.status]!,
  'createdAt': const TimestampDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampDateTimeConverter().toJson(instance.updatedAt),
};

const _$CardStatusEnumMap = {
  CardStatus.pendingIndustry: 'pending_industry',
  CardStatus.ready: 'ready',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
