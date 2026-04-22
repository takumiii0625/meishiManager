// test/unit/viewmodels_test.dart
//
// Web側 ViewModel Unit Test
//
// 【テスト対象】
//   - AdminUsersViewModel : フィルタリング（検索・ステータス）
//   - AdminDashboardViewModel : 統計計算・timeAgo・actionLabel
//   - WebAuthViewModel : バリデーション・エラーメッセージ変換
//
// 【実行方法】
//   flutter test test/unit/viewmodels_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meishi_manager/models/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:meishi_manager/models/viewmodels/admin_users_viewmodel.dart';
import 'package:meishi_manager/repositories/admin_repository.dart';

void main() {
  // ================================================================
  // AdminUsersViewModel - フィルタリング
  // ================================================================
  group('AdminUsersViewModel - applyFilter', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AdminRepository repository;
    late AdminUsersViewModel viewModel;
    late List<QueryDocumentSnapshot> docs;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      repository = AdminRepository(fakeFirestore);
      viewModel = AdminUsersViewModel(repository);

      // テスト用ユーザーデータを作成
      await fakeFirestore.collection('users').doc('user-1').set({
        'name': '山田太郎',
        'email': 'yamada@example.com',
        'company': '株式会社テック',
        'status': 'active',
        'role': 'user',
      });
      await fakeFirestore.collection('users').doc('user-2').set({
        'name': '鈴木花子',
        'email': 'suzuki@example.com',
        'company': 'テスト商事',
        'status': 'suspended',
        'role': 'user',
      });
      await fakeFirestore.collection('users').doc('user-3').set({
        'name': '田中一郎',
        'email': 'tanaka@test.co.jp',
        'company': '株式会社テック',
        'status': 'active',
        'role': 'admin',
      });

      final snapshot = await fakeFirestore.collection('users').get();
      docs = snapshot.docs;
    });

    // ── 検索フィルター ──
    test('検索クエリが空の場合は全件返す', () {
      viewModel.setSearchQuery('');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 3);
    });

    test('名前で検索できる', () {
      viewModel.setSearchQuery('山田');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 1);
      final d = result.first.data() as Map<String, dynamic>;
      expect(d['name'], '山田太郎');
    });

    test('メールアドレスで検索できる', () {
      viewModel.setSearchQuery('suzuki');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 1);
      final d = result.first.data() as Map<String, dynamic>;
      expect(d['email'], 'suzuki@example.com');
    });

    test('会社名で検索できる', () {
      viewModel.setSearchQuery('株式会社テック');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 2);
    });

    test('大文字小文字を区別しない', () {
      viewModel.setSearchQuery('YAMADA');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 1);
    });

    test('一致しない検索クエリは0件返す', () {
      viewModel.setSearchQuery('存在しないユーザー');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 0);
    });

    // ── ステータスフィルター ──
    test('statusFilter=allの場合は全件返す', () {
      viewModel.setStatusFilter('all');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 3);
    });

    test('statusFilter=activeの場合はactiveのみ返す', () {
      viewModel.setStatusFilter('active');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 2);
      for (final doc in result) {
        final d = doc.data() as Map<String, dynamic>;
        expect(d['status'], 'active');
      }
    });

    test('statusFilter=suspendedの場合はsuspendedのみ返す', () {
      viewModel.setStatusFilter('suspended');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 1);
      final d = result.first.data() as Map<String, dynamic>;
      expect(d['status'], 'suspended');
    });

    // ── 複合フィルター ──
    test('検索クエリとステータスフィルターを組み合わせられる', () {
      viewModel.setSearchQuery('株式会社テック');
      viewModel.setStatusFilter('active');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 2);
    });

    test('検索クエリとステータスフィルターで0件になる場合', () {
      viewModel.setSearchQuery('鈴木');
      viewModel.setStatusFilter('active');
      final result = viewModel.applyFilter(docs);
      expect(result.length, 0);
    });

    // ── 状態変更 ──
    test('setSearchQueryで状態が変わる', () {
      viewModel.setSearchQuery('テスト');
      expect(viewModel.searchQuery, 'テスト');
    });

    test('setStatusFilterで状態が変わる', () {
      viewModel.setStatusFilter('suspended');
      expect(viewModel.statusFilter, 'suspended');
    });
  });

  // ================================================================
  // AdminDashboardViewModel - 統計計算
  // ================================================================
  group('AdminDashboardViewModel - calcMonthlyRegistrations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AdminDashboardViewModel viewModel;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      viewModel = AdminDashboardViewModel(fakeFirestore);
    });

    test('ユーザーが0件の場合は全月0を返す', () async {
      final snapshot = await fakeFirestore.collection('users').get();
      final result = viewModel.calcMonthlyRegistrations(snapshot.docs);
      expect(result.length, 12);
      expect(result.values.every((v) => v == 0), true);
    });

    test('今月登録したユーザーが正しくカウントされる', () async {
      final now = DateTime.now();
      await fakeFirestore.collection('users').add({
        'name': 'テストユーザー',
        'createdAt': Timestamp.fromDate(now),
      });
      final snapshot = await fakeFirestore.collection('users').get();
      final result = viewModel.calcMonthlyRegistrations(snapshot.docs);
      final key = '${now.year}/${now.month.toString().padLeft(2, '0')}';
      expect(result[key], 1);
    });

    test('12ヶ月前より古いユーザーはカウントされない', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 400));
      await fakeFirestore.collection('users').add({
        'name': '古いユーザー',
        'createdAt': Timestamp.fromDate(oldDate),
      });
      final snapshot = await fakeFirestore.collection('users').get();
      final result = viewModel.calcMonthlyRegistrations(snapshot.docs);
      expect(result.values.every((v) => v == 0), true);
    });

    test('createdAtがnullのユーザーは無視される', () async {
      await fakeFirestore.collection('users').add({
        'name': 'createdAtなし',
        'createdAt': null,
      });
      final snapshot = await fakeFirestore.collection('users').get();
      final result = viewModel.calcMonthlyRegistrations(snapshot.docs);
      expect(result.values.every((v) => v == 0), true);
    });

    test('結果は常に12件のキーを持つ', () async {
      final snapshot = await fakeFirestore.collection('users').get();
      final result = viewModel.calcMonthlyRegistrations(snapshot.docs);
      expect(result.length, 12);
    });
  });

  group('AdminDashboardViewModel - calcThisMonthRegistrations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AdminDashboardViewModel viewModel;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      viewModel = AdminDashboardViewModel(fakeFirestore);
    });

    test('今月のユーザー数が正しくカウントされる', () async {
      final now = DateTime.now();
      await fakeFirestore.collection('users').add({
        'createdAt': Timestamp.fromDate(now),
      });
      await fakeFirestore.collection('users').add({
        'createdAt': Timestamp.fromDate(now),
      });
      final snapshot = await fakeFirestore.collection('users').get();
      expect(viewModel.calcThisMonthRegistrations(snapshot.docs), 2);
    });

    test('先月のユーザーはカウントされない', () async {
      final lastMonth = DateTime(
          DateTime.now().year, DateTime.now().month - 1, 1);
      await fakeFirestore.collection('users').add({
        'createdAt': Timestamp.fromDate(lastMonth),
      });
      final snapshot = await fakeFirestore.collection('users').get();
      expect(viewModel.calcThisMonthRegistrations(snapshot.docs), 0);
    });

    test('ユーザーが0件の場合は0を返す', () async {
      final snapshot = await fakeFirestore.collection('users').get();
      expect(viewModel.calcThisMonthRegistrations(snapshot.docs), 0);
    });
  });

  // ================================================================
  // AdminDashboardViewModel - actionLabel
  // ================================================================
  group('AdminDashboardViewModel - actionLabel', () {
    late AdminDashboardViewModel viewModel;

    setUp(() {
      viewModel = AdminDashboardViewModel(FakeFirebaseFirestore());
    });

    test('view_cardsは名刺閲覧を返す', () {
      expect(viewModel.actionLabel('view_cards'), '名刺閲覧');
    });

    test('edit_userはユーザー編集を返す', () {
      expect(viewModel.actionLabel('edit_user'), 'ユーザー編集');
    });

    test('delete_userはユーザー削除を返す', () {
      expect(viewModel.actionLabel('delete_user'), 'ユーザー削除');
    });

    test('create_userはユーザー作成を返す', () {
      expect(viewModel.actionLabel('create_user'), 'ユーザー作成');
    });

    test('未定義のアクションはそのまま返す', () {
      expect(viewModel.actionLabel('unknown_action'), 'unknown_action');
    });
  });

  // ================================================================
  // AdminDashboardViewModel - timeAgo
  // ================================================================
  group('AdminDashboardViewModel - timeAgo', () {
    late AdminDashboardViewModel viewModel;

    setUp(() {
      viewModel = AdminDashboardViewModel(FakeFirebaseFirestore());
    });

    test('1分以内はたった今を返す', () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(viewModel.timeAgo(now), 'たった今');
    });

    test('1時間以内は〇分前を返す', () {
      final now = DateTime.now().subtract(const Duration(minutes: 30));
      expect(viewModel.timeAgo(now), '30分前');
    });

    test('24時間以内は〇時間前を返す', () {
      final now = DateTime.now().subtract(const Duration(hours: 3));
      expect(viewModel.timeAgo(now), '3時間前');
    });

    test('7日以内は〇日前を返す', () {
      final now = DateTime.now().subtract(const Duration(days: 3));
      expect(viewModel.timeAgo(now), '3日前');
    });

    test('7日以上前は月/日を返す', () {
      final date = DateTime.now().subtract(const Duration(days: 10));
      final result = viewModel.timeAgo(date);
      expect(result, '${date.month}/${date.day}');
    });
  });
}
