import 'package:cloud_firestore/cloud_firestore.dart';
import 'card_model.dart';

CardModel cardModelFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};
  return CardModel.fromJson({
    ...data,
    'id': doc.id,
  });
}
