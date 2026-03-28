// ============================================================
// card_model_mapper.dart
// FirestoreのドキュメントデータをCardModelに変換するファイル
//
// 【なぜこのファイルが必要？】
//   Firestoreから取得したデータは Map<String, dynamic> という形式。
//   そのままでは使いにくいので CardModel に変換する処理をここに書く。
//   フィールドが存在しない場合も安全に空文字やデフォルト値で補完する。
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'card_model.dart';

/// FirestoreのDocumentSnapshot → CardModel に変換する関数
CardModel cardModelFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  // doc.data() がnullの場合（ドキュメントが存在しない）は空のMapを使う
  final data = doc.data() ?? <String, dynamic>{};
  // serverTimestamp()が未反映の場合（保存直後など）の代替値
  final now = Timestamp.now();

  return CardModel.fromJson({
    // ドキュメントIDをidフィールドに設定
    'id': doc.id,

    // ── 基本情報（as String? で型変換、?? '' でnull時は空文字）──
    'name':     (data['name']     as String?) ?? '',
    'company':  (data['company']  as String?) ?? '',
    'industry': (data['industry'] as String?) ?? '',
    'phone':    (data['phone']    as String?) ?? '',
    'email':    (data['email']    as String?) ?? '',
    'address':  (data['address']  as String?) ?? '',
    'notes':    (data['notes']    as String?) ?? '',
    'rawText':  (data['rawText']  as String?) ?? '',

    // ── 所属情報 ──────────────────────────────────────────────
    // 古いデータには department がない場合があるので ?? '' でフォールバック
    'department': (data['department'] as String?) ?? '',
    'jobLevel':   (data['jobLevel']   as String?) ?? '',

    // ── 画像URL ──────────────────────────────────────────────
    // 旧フィールド名 'imageUrl' からのフォールバックで互換性を保つ
    'frontImageUrl': (data['frontImageUrl'] as String?)
        ?? (data['imageUrl'] as String?) // 旧フィールド名からのフォールバック
        ?? '',
    'backImageUrl': (data['backImageUrl'] as String?) ?? '',

    // ── フィルター用フィールド ──
    'prefecture': (data['prefecture'] as String?) ?? '',

    // タグはList<String>なので専用の変換処理
    'tags': (data['tags'] as List<dynamic>?)
            ?.map((e) => e.toString()).toList() ?? [],

    'industryCandidates': (data['industryCandidates'] as List<dynamic>?)
            ?.map((e) => e.toString()).toList() ?? [],

    // ── 論理削除フィールド ──
    'isDeleted': (data['isDeleted'] as bool?) ?? false,
    'deletedAt': data['deletedAt'], // nullでもOK

    // ── ステータス（なければ pending_industry）──
    'status': (data['status'] as String?) ?? 'pending_industry',

    // ── タイムスタンプ（serverTimestamp未反映時は now で補完）──
    'createdAt': data['createdAt'] ?? now,
    'updatedAt': data['updatedAt'] ?? now,
  });
}
