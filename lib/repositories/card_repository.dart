// ============================================================
// card_repository.dart
// Firestoreへの読み書きを担当するクラス
//
// 【Repositoryパターンとは？】
//   画面（View）が直接 Firestore を触るのではなく、
//   このクラスを通じてデータのやりとりをする設計パターン。
//   メリット：
//     ・画面側のコードがシンプルになる
//     ・データの取得・保存ロジックが1か所に集まる
//     ・将来DBを変えても画面側を修正しなくて済む
//
// 【Firestoreのデータ構造】
//   /users/{uid}/cards/{cardId}
//   uid = ログイン中のユーザーID（FirebaseAuthが発行する一意なID）
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';
import '../models/card_model_mapper.dart';

class CardRepository {
  // コンストラクタ：外から FirebaseFirestore インスタンスを受け取る
  // これにより、テスト時にモック（偽物）を渡せる
  CardRepository(this._db);
  final FirebaseFirestore _db;

  /// /users/{uid}/cards というコレクションへの参照を返すヘルパー
  /// 各メソッドで毎回書かなくて済むように共通化している
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('cards');

  /// 通常の名刺一覧（ゴミ箱以外）をリアルタイム監視するStream
  ///
  /// Stream = データが変わるたびに自動で新しい値が流れてくる仕組み
  /// .snapshots() = Firestoreのリアルタイム監視を開始する
  /// .map() = 流れてきたデータを CardModel に変換する
  Stream<List<CardModel>> watchCards(String uid) {
    return _col(uid)
        .where('isDeleted', isEqualTo: false) // ゴミ箱の名刺を除外
        .orderBy('createdAt', descending: true) // 新しい順に並べる
        .snapshots()
        .map((snap) => snap.docs.map(cardModelFromDoc).toList());
  }

  /// ゴミ箱の名刺一覧をリアルタイム監視するStream
  Stream<List<CardModel>> watchTrashCards(String uid) {
    return _col(uid)
        .where('isDeleted', isEqualTo: true) // ゴミ箱の名刺だけ取得
        .orderBy('deletedAt', descending: true) // 削除が新しい順
        .snapshots()
        .map((snap) => snap.docs.map(cardModelFromDoc).toList());
  }

  /// 名刺1件をリアルタイム監視するStream（詳細画面用）
  /// .doc(cardId) = 特定の1件を指定する
  Stream<CardModel> watchCard(String uid, String cardId) {
    return _col(uid)
        .doc(cardId)
        .snapshots()
        .map((doc) => cardModelFromDoc(doc));
  }

  /// 名刺を新規追加する
  ///
  /// named parameters（名前付き引数）を使っているので、
  /// 呼び出し時に引数名を書く必要がある。
  /// 例: addCard(uid, name: '山田太郎', company: '株式会社テック')
  Future<void> addCard(
    String uid, {
    required String name,    // required = 省略不可
    required String company, // required = 省略不可
    String industry = '',    // デフォルト値あり = 省略可能
    String phone = '',
    String email = '',
    String address = '',
    String notes = '',
    String frontImageUrl = '',
    String backImageUrl = '',
    String rawText = '',
    String prefecture = '',
    String department = '', // 部署
    String jobLevel = '',   // 役職
    List<String> tags = const [],
    List<String> industryCandidates = const [],
  }) async {
    final now = DateTime.now();
    // .add() = 新しいドキュメントをランダムIDで追加する
    await _col(uid).add({
      'name': name,
      'company': company,
      'industry': industry,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'rawText': rawText,
      'prefecture': prefecture,
      'department': department, // 部署
      'jobLevel': jobLevel,     // 役職
      'tags': tags,
      'industryCandidates': industryCandidates,
      'isDeleted': false,       // 新規追加時は必ずfalse
      'deletedAt': null,
      'status': 'pending_industry',
      // Timestamp.fromDate() = DateTime を Firestore のタイムスタンプ型に変換
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// 名刺を更新する
  ///
  /// .update() = 指定したフィールドだけを上書きする
  /// （指定しなかったフィールドは変わらない）
  Future<void> updateCard(
    String uid,
    String cardId, {
    required String name,
    required String company,
    String industry = '',
    String phone = '',
    String email = '',
    String address = '',
    String notes = '',
    String frontImageUrl = '',
    String backImageUrl = '',
    String rawText = '',
    String prefecture = '',
    String department = '', // 部署
    String jobLevel = '',   // 役職
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    await _col(uid).doc(cardId).update({
      'name': name,
      'company': company,
      'industry': industry,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'rawText': rawText,
      'prefecture': prefecture,
      'department': department, // 部署
      'jobLevel': jobLevel,     // 役職
      'tags': tags,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// 論理削除：ゴミ箱に移動する
  ///
  /// 「論理削除」= 実際にデータを消さず、フラグを立てるだけ
  /// isDeleted を true にするだけなので、あとで復元できる
  Future<void> moveToTrash(String uid, String cardId) async {
    await _col(uid).doc(cardId).update({
      'isDeleted': true,
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// ゴミ箱から復元する（isDeleted を false に戻す）
  Future<void> restoreFromTrash(String uid, String cardId) async {
    await _col(uid).doc(cardId).update({
      'isDeleted': false,
      'deletedAt': null, // 削除日時もリセット
    });
  }

  /// 完全削除：Firestoreからドキュメントを物理的に消す
  ///
  /// .delete() = ドキュメントそのものを消す（取り消し不可）
  Future<void> deleteCard(String uid, String cardId) async {
    await _col(uid).doc(cardId).delete();
  }

  /// タグだけを更新する（詳細画面のタグ編集専用）
  Future<void> updateTags(String uid, String cardId, List<String> tags) async {
    await _col(uid).doc(cardId).update({
      'tags': tags,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
