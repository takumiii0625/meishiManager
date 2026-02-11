import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Firestore Timestamp <-> Dart DateTime converter for json_serializable.
class TimestampDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const TimestampDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json == null) {
      // 必須にしたい場合は例外でもOK。今回は安全側でepoch。
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) return DateTime.tryParse(json) ?? DateTime.fromMillisecondsSinceEpoch(0);

    throw ArgumentError('Unsupported timestamp type: ${json.runtimeType}');
  }

  @override
  Object? toJson(DateTime object) {
    // Firestoreへ書くときは Timestamp を推奨
    return Timestamp.fromDate(object);
  }
}
