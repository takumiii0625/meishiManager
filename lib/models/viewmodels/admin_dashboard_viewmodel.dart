import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  AdminDashboardViewModel(this._db);

  final FirebaseFirestore _db;

  // ----------------------------------------------------------------
  // ユーザー一覧ストリーム
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchUsers() =>
      _db.collection('users').snapshots();

  // ----------------------------------------------------------------
  // アクセスログ（最新5件）
  // ----------------------------------------------------------------
  Stream<QuerySnapshot> watchRecentAccessLogs() =>
      _db
          .collection('admin_access_logs')
          .orderBy('accessedAt', descending: true)
          .limit(5)
          .snapshots();

  // ----------------------------------------------------------------
  // 月別ユーザー登録数を集計（過去12ヶ月）
  // ----------------------------------------------------------------
  Map<String, int> calcMonthlyRegistrations(
      List<QueryDocumentSnapshot> users) {
    final now = DateTime.now();
    final Map<String, int> monthly = {};

    for (int i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key =
          '${d.year}/${d.month.toString().padLeft(2, '0')}';
      monthly[key] = 0;
    }

    for (final user in users) {
      final data = user.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      final key =
          '${date.year}/${date.month.toString().padLeft(2, '0')}';
      if (monthly.containsKey(key)) {
        monthly[key] = (monthly[key] ?? 0) + 1;
      }
    }

    return monthly;
  }

  // ----------------------------------------------------------------
  // 今月の新規登録数
  // ----------------------------------------------------------------
  int calcThisMonthRegistrations(List<QueryDocumentSnapshot> users) {
    final now = DateTime.now();
    return users.where((user) {
      final data = user.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();
      return date.year == now.year && date.month == now.month;
    }).length;
  }

  // ----------------------------------------------------------------
  // アクションラベル（日本語）
  // ----------------------------------------------------------------
  String actionLabel(String action) {
    switch (action) {
      case 'view_cards':  return '名刺閲覧';
      case 'edit_user':   return 'ユーザー編集';
      case 'delete_user': return 'ユーザー削除';
      case 'create_user': return 'ユーザー作成';
      default:            return action;
    }
  }

  // ----------------------------------------------------------------
  // 経過時間の表示
  // ----------------------------------------------------------------
  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24)   return '${diff.inHours}時間前';
    if (diff.inDays < 7)     return '${diff.inDays}日前';
    return '${date.month}/${date.day}';
  }
}
