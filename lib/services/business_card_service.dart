// lib/services/business_card_service.dart
//
// 【このファイルの役割】
//   1. 画像をFirebase Storageにアップロードする
//   2. Geminiの解析結果をFirestoreに保存する
//
// 【department / jobLevel の扱い】
//   部署（department）＞役職（jobLevel）の優先度で保存・表示する。
//   役職がない名刺でも部署があれば所属がわかる設計。
//   両方ある場合は両方保存する。
//
// 【表裏の画像保存について】
//   ファイル名に front_ / back_ プレフィックスをつけて確実に区別する。
//   以前は並列アップロード（Future.wait）でタイムスタンプが衝突するリスクがあったため
//   直列アップロードに変更した。

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_compress_service.dart';

class BusinessCardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _joinList(dynamic v) {
    if (v is List) {
      return v.whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ');
    }
    if (v is String) return v;
    return '';
  }

  // ─────────────────────────────────────────────────────────
  // 画像をFirebase StorageにアップロードしてダウンロードURLを返す
  //
  // [prefix] : 'front' or 'back' をファイル名に含めて表裏を区別する
  // ─────────────────────────────────────────────────────────
  Future<String?> uploadImage(String imagePath, {String prefix = 'card'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    File? compressed;
    try {
      compressed = await ImageCompressService.compressForUpload(imagePath);

      // ★ prefix（front/back）をつけてファイル名を区別する
      // 例: front_1234567890.jpg / back_1234567890.jpg
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('cards')
          .child(fileName);

      await storageRef.putFile(
        compressed,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await storageRef.getDownloadURL();
      return url;
    } catch (e) {
      print('Storageアップロード失敗: $e');
      return null;
    } finally {
      // アップロード完了またはエラー時、必ず一時ファイルを削除する
      // finally = try/catchどちらの結果でも必ず実行されるブロック
      if (compressed != null) {
        await ImageCompressService.deleteTemp(compressed);
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // 名刺データをFirestoreに保存する
  // ─────────────────────────────────────────────────────────
  Future<String> addCard({
    required Map<String, dynamic> card,
    required String rawText,
    String? frontImagePath,
    String? backImagePath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ログイン情報がありません');

    // ★ 直列アップロードに変更（並列だとタイムスタンプが衝突する可能性あり）
    //   表面 → 裏面の順で1枚ずつアップロードして確実に区別する
    final frontImageUrl = (frontImagePath != null && frontImagePath.isNotEmpty)
        ? await uploadImage(frontImagePath, prefix: 'front') ?? ''
        : '';

    final backImageUrl = (backImagePath != null && backImagePath.isNotEmpty)
        ? await uploadImage(backImagePath, prefix: 'back') ?? ''
        : '';

    // ── Geminiの解析結果から各フィールドを取り出す ────────
    final company    = (card['company']     as String?) ?? '';
    final nameJa     = (card['name_ja']     as String?) ?? '';
    final nameEn     = (card['name_en']     as String?) ?? '';
    final postal     = (card['postal_code'] as String?) ?? '';
    final address    = (card['address']     as String?) ?? '';
    final name       = nameJa.isNotEmpty ? nameJa : nameEn;
    final phone      = _joinList(card['phone']);
    final email      = _joinList(card['email']);
    final url        = _joinList(card['url']);
    final prefecture = (card['prefecture']  as String?) ?? '';

    // 部署：Geminiの department フィールドをそのまま使う
    final department = (card['department'] as String?) ?? '';

    // 役職：Geminiの title フィールドをそのまま使う（正規化しない）
    final jobLevel   = (card['title'] as String?) ?? '';

    final industryRaw = (card['industry'] as String?) ?? '';

    // industry_candidates はGeminiから [{label, confidence}, ...] の形で返ってくる。
    // モデルは List<String> なので、ラベル名だけ抽出してリストに変換する。
    // 例: [{"label": "IT", "confidence": 0.9}] → ["IT"]
    final rawCandidates = (card['industry_candidates'] as List?) ?? [];
    final candidates = rawCandidates
        .map((e) {
          if (e is Map) return (e['label'] as String?) ?? '';
          if (e is String) return e; // すでに文字列の場合はそのまま使う
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();

    // メモ欄：郵便番号・URLのみ（部署・役職は専用フィールドで管理）
    final notesParts = <String>[];
    if (postal.isNotEmpty) notesParts.add('〒$postal');
    if (url.isNotEmpty)    notesParts.add('URL: $url');
    final notes = notesParts.join('\n');

    final now = FieldValue.serverTimestamp();

    final doc = <String, dynamic>{
      'uid':        user.uid,
      'name':       name,
      'company':    company,
      'phone':      phone,
      'email':      email,
      'address':    address,
      'prefecture': prefecture,
      'department': department,
      'jobLevel':   jobLevel,
      'industry':           industryRaw,
      'industryCandidates': candidates,
      'tags':       <String>[],
      'notes':      notes,
      // ★ frontImageUrl と backImageUrl を明確に区別して保存
      'frontImageUrl': frontImageUrl, // 表面（front_ プレフィックスのファイル）
      'backImageUrl':  backImageUrl,  // 裏面（back_ プレフィックスのファイル）
      'rawText':       rawText,
      'isDeleted': false,
      'deletedAt': null,
      'status':    'pending_industry',
      'createdAt': now,
      'updatedAt': now,
      '_rawCard':  card,
    };

    final ref = await _db
        .collection('users')
        .doc(user.uid)
        .collection('cards')
        .add(doc);

    return ref.id;
  }
}
