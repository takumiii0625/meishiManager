// lib/models/card_model_mapper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'card_model.dart';

CardModel cardModelFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};
  final now = Timestamp.now();

  return CardModel.fromJson({
    'id': doc.id,

    // ✅ 文字列は全部 null-safe
    'name': (data['name'] as String?) ?? '',
    'company': (data['company'] as String?) ?? '',
    'industry': (data['industry'] as String?) ?? '',
    'phone': (data['phone'] as String?) ?? '',
    'email': (data['email'] as String?) ?? '',
    'notes': (data['notes'] as String?) ?? '',
    'imageUrl': (data['imageUrl'] as String?) ?? '',
    'rawText': (data['rawText'] as String?) ?? '',

    // ✅ enum（無ければ pending）
    'status': (data['status'] as String?) ?? 'pending_industry',

    // ✅ serverTimestamp直後はnullになり得るのでnowで埋める
    'createdAt': data['createdAt'] ?? now,
    'updatedAt': data['updatedAt'] ?? now,
  });
}
