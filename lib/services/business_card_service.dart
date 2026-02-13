import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessCardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _joinList(dynamic v) {
    if (v is List) {
      return v.whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ');
    }
    if (v is String) return v;
    return '';
  }

  Future<String> addCard({
    required Map<String, dynamic> card,
    required String rawText,
    String? imagePath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ログイン情報がありません');
    }

    final colRef = _db.collection('users').doc(user.uid).collection('cards');

    // --- Gemini card から取り出し（null-safe）---
    final company = (card['company'] as String?) ?? '';
    final nameJa = (card['name_ja'] as String?) ?? '';
    final nameEn = (card['name_en'] as String?) ?? '';
    final name = nameJa.isNotEmpty ? nameJa : nameEn;

    final phone = _joinList(card['phone']); // ← 配列対応
    final email = _joinList(card['email']);
    final url = _joinList(card['url']);

    final department = (card['department'] as String?) ?? '';
    final title = (card['title'] as String?) ?? '';
    final postal = (card['postal_code'] as String?) ?? '';
    final address = (card['address'] as String?) ?? '';

    // notes に寄せる（CardModelが notes を持ってるので活用）
    final notesParts = <String>[];
    if (department.isNotEmpty) notesParts.add('部署: $department');
    if (title.isNotEmpty) notesParts.add('役職: $title');
    if (postal.isNotEmpty) notesParts.add('〒$postal');
    if (address.isNotEmpty) notesParts.add(address);
    if (url.isNotEmpty) notesParts.add('URL: $url');
    final notes = notesParts.join('\n');

    final now = FieldValue.serverTimestamp();

    final doc = <String, dynamic>{
      'uid': user.uid,

      // ✅ CardModel.requiredに合わせたフラット（ここが自動入力になる）
      'name': name,
      'company': company,
      'industry': '',
      'phone': phone,
      'email': email,
      'notes': notes,
      'imageUrl': '',

      'rawText': rawText,
      'status': 'pending_industry',
      'createdAt': now,
      'updatedAt': now,

      // ✅ 生データ（詳細画面/将来の再解析用）
      'card': card,
      'imagePath': imagePath,
    };

    final ref = await colRef.add(doc);
    return ref.id;
  }
}
