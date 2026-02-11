// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CardModelImpl _$$CardModelImplFromJson(Map<String, dynamic> json) =>
    _$CardModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      company: json['company'] as String,
      industry: json['industry'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      notes: json['notes'] as String,
      imageUrl: json['imageUrl'] as String,
      rawText: json['rawText'] as String,
      status: $enumDecode(_$CardStatusEnumMap, json['status']),
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
  'notes': instance.notes,
  'imageUrl': instance.imageUrl,
  'rawText': instance.rawText,
  'status': _$CardStatusEnumMap[instance.status]!,
  'createdAt': const TimestampDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampDateTimeConverter().toJson(instance.updatedAt),
};

const _$CardStatusEnumMap = {
  CardStatus.pendingIndustry: 'pending_industry',
  CardStatus.ready: 'ready',
};
