import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/card_model.dart';
import '../models/card_model_mapper.dart';

class CardRepository {
  CardRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('cards');

  Stream<List<CardModel>> watchCards(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(cardModelFromDoc).toList());
  }

  /// 動作確認用：ダミー追加（残してOK）
  Future<void> addDummy(String uid) async {
    final now = DateTime.now();
    await _col(uid).add({
      'name': '山田 太郎',
      'company': 'テスト株式会社',
      'industry': '',
      'phone': '090-0000-0000',
      'email': 'test@example.com',
      'notes': 'ダミー',
      'imageUrl': '',
      'rawText': '',
      'status': 'pending_industry',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// 本命：フォーム入力で追加
  Future<void> addCard(
    String uid, {
    required String name,
    required String company,
    String industry = '',
    String phone = '',
    String email = '',
    String notes = '',
    String imageUrl = '',
    String rawText = '',
  }) async {
    final now = DateTime.now();

    await _col(uid).add({
      'name': name,
      'company': company,
      'industry': industry,
      'phone': phone,
      'email': email,
      'notes': notes,
      'imageUrl': imageUrl,
      'rawText': rawText,
      'status': 'pending_industry',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateCard(
    String uid,
    String cardId, {
    required String name,
    required String company,
    String industry = '',
    String phone = '',
    String email = '',
    String notes = '',
    String imageUrl = '',
    String rawText = '',
  }) async {
    final now = DateTime.now();

    await _col(uid).doc(cardId).update({
      'name': name,
      'company': company,
      'industry': industry,
      'phone': phone,
      'email': email,
      'notes': notes,
      'imageUrl': imageUrl,
      'rawText': rawText,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> deleteCard(String uid, String cardId) async {
    await _col(uid).doc(cardId).delete();
  }

  Stream<CardModel> watchCard(String uid, String cardId) {
    return _col(uid)
        .doc(cardId)
        .snapshots()
        .map((doc) => cardModelFromDoc(doc));
  }
}
