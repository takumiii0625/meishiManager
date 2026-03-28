import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../repositories/admin_repository.dart';

/// 管理画面ユーザー管理のビジネスロジックを集約するViewModel
class AdminUsersViewModel extends ChangeNotifier {
  AdminUsersViewModel(this._repository);

  final AdminRepository _repository;

  // ----------------------------------------------------------------
  // 状態
  // ----------------------------------------------------------------
  String searchQuery  = '';
  String statusFilter = 'all';

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // ユーザー一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchUsers() => _repository.watchUsers();

  // ----------------------------------------------------------------
  // ユーザー作成（別インスタンス方式）
  // ----------------------------------------------------------------
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String company,
    required String role,
  }) async {
    FirebaseApp? tempApp;
    try {
      // ① 別Firebaseインスタンスを一時生成（管理者セッションを守るため）
      tempApp = await Firebase.initializeApp(
        name: 'tempUserCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      // ② 別インスタンスでAuth登録（管理者のセッションに影響なし）
      final credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // ③ Firestoreにユーザー情報を保存
      await _repository.createUserDoc(
        uid: uid,
        name: name,
        email: email,
        company: company,
        role: role,
      );

      // ④ アクセスログを記録
      await writeAccessLog(
        targetUserId: uid,
        action: 'create_user',
        detail: '$name を新規作成',
      );
    } finally {
      // ⑤ 別インスタンスを必ず破棄
      await tempApp?.delete();
    }
  }

  // ----------------------------------------------------------------
  // ユーザー編集
  // ----------------------------------------------------------------
  Future<void> updateUser({
    required String userId,
    required String name,
    required String email,
    required String company,
    required String status,
    required String role,
    required String oldStatus,
  }) async {
    await _repository.updateUserDoc(
      userId: userId,
      data: {
        'name': name,
        'email': email,
        'company': company,
        'status': status,
        'role': role,
      },
    );

    // ステータスが変わった場合は詳細を記録
    final detail = oldStatus != status
        ? 'ステータス変更: $oldStatus → $status'
        : 'ユーザー情報を編集';

    await writeAccessLog(
      targetUserId: userId,
      action: 'edit_user',
      detail: detail,
    );
  }

  // ----------------------------------------------------------------
  // ユーザー削除
  // ----------------------------------------------------------------
  Future<void> deleteUser({
    required String userId,
    required String userName,
  }) async {
    // ログは削除前に記録（削除後はルール違反になる可能性があるため）
    await writeAccessLog(
      targetUserId: userId,
      action: 'delete_user',
      detail: '$userName を削除',
    );
    await _repository.deleteUserDoc(userId);
  }

  // ----------------------------------------------------------------
  // 名刺一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchBusinessCards(String userId) =>
      _repository.watchBusinessCards(userId);

  // ----------------------------------------------------------------
  // アクセスログ一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchAccessLogs(String targetUserId) =>
      _repository.watchAccessLogs(targetUserId);

  // ----------------------------------------------------------------
  // アクセスログ記録
  // ※ ViewModelに集約することで、どこからでも一貫した形式で記録できる
  // ----------------------------------------------------------------
  Future<void> writeAccessLog({
    required String targetUserId,
    required String action,
    String detail = '',
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    // 管理者名をFirestoreから取得（なければメールアドレスを使用）
    String adminName = admin.email ?? admin.uid;
    try {
      final doc = await _repository.fetchUserDoc(admin.uid);
      if (doc.exists) {
        adminName = (doc.data() as Map<String, dynamic>?)?['name'] ?? adminName;
      }
    } catch (_) {}

    await _repository.addAccessLog({
      'adminUid': admin.uid,
      'adminName': adminName,
      'targetUserId': targetUserId,
      'action': action,
      'detail': detail,
      'accessedAt': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------------
  // フィルタリング（ViewModel内で完結させる）
  // ----------------------------------------------------------------
  List<QueryDocumentSnapshot> applyFilter(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final name    = (d['name']    as String? ?? '').toLowerCase();
      final email   = (d['email']   as String? ?? '').toLowerCase();
      final company = (d['company'] as String? ?? '').toLowerCase();
      final status  = d['status']   as String? ?? '';
      final q = searchQuery.toLowerCase();

      final matchSearch = q.isEmpty ||
          name.contains(q) ||
          email.contains(q) ||
          company.contains(q);
      final matchStatus = statusFilter == 'all' || status == statusFilter;

      return matchSearch && matchStatus;
    }).toList();
  }
}
