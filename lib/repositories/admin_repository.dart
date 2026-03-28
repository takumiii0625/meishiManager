import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminRepository {
  AdminRepository(this._db);

  final FirebaseFirestore _db;

  // ----------------------------------------------------------------
  // ユーザー一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchUsers() =>
      _db.collection('users').snapshots();

  // ----------------------------------------------------------------
  // ユーザー1件取得
  // ----------------------------------------------------------------
  Future<DocumentSnapshot> fetchUserDoc(String uid) =>
      _db.collection('users').doc(uid).get();

  // ----------------------------------------------------------------
  // ユーザー作成（別インスタンス方式・Auth登録 + Firestore保存）
  // ----------------------------------------------------------------
  Future<void> createUserDoc({
    required String uid,
    required String name,
    required String email,
    required String company,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'company': company,
      'role': role,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------------
  // ユーザー編集（DB操作のみ・ロジックはViewModelに集約）
  // ----------------------------------------------------------------
  Future<void> updateUserDoc({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------------
  // ユーザー削除
  // ----------------------------------------------------------------
  Future<void> deleteUserDoc(String userId) =>
      _db.collection('users').doc(userId).delete();

  // ----------------------------------------------------------------
  // 名刺一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchBusinessCards(String userId) =>
      _db
          .collection('users')
          .doc(userId)
          .collection('business_cards')
          .snapshots();

  // ----------------------------------------------------------------
  // アクセスログ一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchAccessLogs(String targetUserId) =>
      _db
          .collection('admin_access_logs')
          .where('targetUserId', isEqualTo: targetUserId)
          .orderBy('accessedAt', descending: true)
          .limit(50)
          .snapshots();

  // ----------------------------------------------------------------
  // アクセスログ追加（データはViewModelで組み立てる）
  // ----------------------------------------------------------------
  Future<void> addAccessLog(Map<String, dynamic> data) =>
      _db.collection('admin_access_logs').add(data);
}