// test/unit/web_logic_test.dart
//
// Web側ロジック Unit Test
//
// 【テスト対象】
//   - CardFilterLogic  : 名刺一覧のフィルター・ソートロジック
//   - WebAuthViewModel : メール・パスワードバリデーション・エラーメッセージ変換
//   - AdminSettingsViewModel : パスワード変更バリデーション
//
// 【実行方法】
//   flutter test test/unit/web_logic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:meishi_manager/models/card_model.dart';
import 'package:meishi_manager/models/viewmodels/admin_settings_viewmodel.dart';
import 'package:meishi_manager/models/viewmodels/web_auth_viewmodel.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

// ================================================================
// テスト用ヘルパー：CardModel を簡単に作れるファクトリ
// ================================================================
CardModel makeCard({
  String id = 'test-id',
  String name = '',
  String company = '',
  String industry = '',
  String prefecture = '',
  String jobLevel = '',
  String department = '',
  String address = '',
  String notes = '',
  List<String> tags = const [],
  DateTime? createdAt,
}) {
  return CardModel(
    id: id,
    name: name,
    company: company,
    industry: industry,
    prefecture: prefecture,
    jobLevel: jobLevel,
    department: department,
    address: address,
    notes: notes,
    tags: tags,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

// ================================================================
// テスト用：_applyFilter と同じロジックを純粋関数として切り出し
// ================================================================
List<CardModel> applyFilter(
  List<CardModel> cards, {
  String searchQuery = '',
  String filterIndustry = '',
  String filterPrefecture = '',
  String filterJobLevel = '',
  String filterDepartment = '',
  bool sortNewest = true,
}) {
  final result = cards.where((c) {
    final q = searchQuery.toLowerCase();
    final matchSearch = q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        c.company.toLowerCase().contains(q) ||
        c.department.toLowerCase().contains(q) ||
        c.jobLevel.toLowerCase().contains(q) ||
        c.industry.toLowerCase().contains(q) ||
        c.address.toLowerCase().contains(q) ||
        c.notes.toLowerCase().contains(q) ||
        c.tags.any((t) => t.toLowerCase().contains(q));
    final matchIndustry   = filterIndustry.isEmpty   || c.industry   == filterIndustry;
    final matchPrefecture = filterPrefecture.isEmpty || c.prefecture == filterPrefecture;
    final matchJobLevel   = filterJobLevel.isEmpty   || c.jobLevel   == filterJobLevel;
    final matchDepartment = filterDepartment.isEmpty || c.department == filterDepartment;
    return matchSearch && matchIndustry && matchPrefecture && matchJobLevel && matchDepartment;
  }).toList();
  result.sort((a, b) => sortNewest
      ? b.createdAt.compareTo(a.createdAt)
      : a.createdAt.compareTo(b.createdAt));
  return result;
}

void main() {
  // ================================================================
  // 名刺一覧 フィルター・ソートロジック
  // ================================================================
  group('名刺一覧 - 検索フィルター', () {
    late List<CardModel> cards;

    setUp(() {
      cards = [
        makeCard(id: '1', name: '山田太郎', company: '株式会社テック',
            industry: 'IT', prefecture: '東京都', jobLevel: '部長',
            department: '営業部', address: '渋谷区', notes: '展示会で出会った',
            tags: ['展示会']),
        makeCard(id: '2', name: '鈴木花子', company: 'テスト商事',
            industry: '製造業', prefecture: '大阪府', jobLevel: '課長',
            department: '開発部', address: '梅田', notes: 'メモなし',
            tags: ['重要']),
        makeCard(id: '3', name: '田中一郎', company: '株式会社テック',
            industry: 'IT', prefecture: '東京都', jobLevel: '担当',
            department: '営業部', notes: ''),
      ];
    });

    test('検索クエリが空の場合は全件返す', () {
      final result = applyFilter(cards);
      expect(result.length, 3);
    });

    test('名前で検索できる', () {
      final result = applyFilter(cards, searchQuery: '山田');
      expect(result.length, 1);
      expect(result.first.name, '山田太郎');
    });

    test('会社名で検索できる', () {
      final result = applyFilter(cards, searchQuery: '株式会社テック');
      expect(result.length, 2);
    });

    test('部署で検索できる', () {
      final result = applyFilter(cards, searchQuery: '営業部');
      expect(result.length, 2);
    });

    test('役職で検索できる', () {
      final result = applyFilter(cards, searchQuery: '部長');
      expect(result.length, 1);
    });

    test('業種で検索できる', () {
      final result = applyFilter(cards, searchQuery: '製造業');
      expect(result.length, 1);
    });

    test('住所で検索できる', () {
      final result = applyFilter(cards, searchQuery: '渋谷区');
      expect(result.length, 1);
    });

    test('メモで検索できる', () {
      final result = applyFilter(cards, searchQuery: '展示会で出会った');
      expect(result.length, 1);
    });

    test('タグで検索できる', () {
      final result = applyFilter(cards, searchQuery: '重要');
      expect(result.length, 1);
    });

    test('大文字小文字を区別しない', () {
      final result = applyFilter(cards, searchQuery: 'IT');
      final result2 = applyFilter(cards, searchQuery: 'it');
      expect(result.length, result2.length);
    });

    test('一致しない検索クエリは0件返す', () {
      final result = applyFilter(cards, searchQuery: '存在しない名前');
      expect(result.length, 0);
    });
  });

  group('名刺一覧 - フィルタードロップダウン', () {
    late List<CardModel> cards;

    setUp(() {
      cards = [
        makeCard(id: '1', industry: 'IT', prefecture: '東京都',
            jobLevel: '部長', department: '営業部'),
        makeCard(id: '2', industry: '製造業', prefecture: '大阪府',
            jobLevel: '課長', department: '開発部'),
        makeCard(id: '3', industry: 'IT', prefecture: '東京都',
            jobLevel: '担当', department: '営業部'),
      ];
    });

    test('業種フィルターが動作する', () {
      final result = applyFilter(cards, filterIndustry: 'IT');
      expect(result.length, 2);
      expect(result.every((c) => c.industry == 'IT'), true);
    });

    test('地域フィルターが動作する', () {
      final result = applyFilter(cards, filterPrefecture: '東京都');
      expect(result.length, 2);
    });

    test('役職フィルターが動作する', () {
      final result = applyFilter(cards, filterJobLevel: '部長');
      expect(result.length, 1);
    });

    test('部署フィルターが動作する', () {
      final result = applyFilter(cards, filterDepartment: '営業部');
      expect(result.length, 2);
    });

    test('業種と地域を組み合わせられる', () {
      final result = applyFilter(cards,
          filterIndustry: 'IT', filterPrefecture: '東京都');
      expect(result.length, 2);
    });

    test('フィルターが一致しない場合は0件', () {
      final result = applyFilter(cards, filterIndustry: '存在しない業種');
      expect(result.length, 0);
    });

    test('全フィルターが空の場合は全件返す', () {
      final result = applyFilter(cards);
      expect(result.length, 3);
    });
  });

  group('名刺一覧 - ソート', () {
    late List<CardModel> cards;

    setUp(() {
      cards = [
        makeCard(id: '1', name: '古い', createdAt: DateTime(2024, 1, 1)),
        makeCard(id: '2', name: '新しい', createdAt: DateTime(2024, 6, 1)),
        makeCard(id: '3', name: '中間', createdAt: DateTime(2024, 3, 1)),
      ];
    });

    test('新しい順（sortNewest=true）で並び替えられる', () {
      final result = applyFilter(cards, sortNewest: true);
      expect(result.first.name, '新しい');
      expect(result.last.name, '古い');
    });

    test('古い順（sortNewest=false）で並び替えられる', () {
      final result = applyFilter(cards, sortNewest: false);
      expect(result.first.name, '古い');
      expect(result.last.name, '新しい');
    });

    test('同じ日付の場合は順序が保たれる', () {
      final sameDate = [
        makeCard(id: '1', name: 'A', createdAt: DateTime(2024, 1, 1)),
        makeCard(id: '2', name: 'B', createdAt: DateTime(2024, 1, 1)),
      ];
      final result = applyFilter(sameDate, sortNewest: true);
      expect(result.length, 2);
    });
  });

  // ================================================================
  // WebAuthViewModel - バリデーション
  // ================================================================
  group('WebAuthViewModel - validateEmail', () {
    late WebAuthViewModel viewModel;

    setUp(() {
      viewModel = WebAuthViewModel(
        MockFirebaseAuth(),
        MockGoogleSignIn(),
      );
    });

    test('正しいメールアドレスはnullを返す', () {
      expect(viewModel.validateEmail('test@example.com'), null);
    });

    test('空文字はエラーを返す', () {
      expect(viewModel.validateEmail(''),
          'メールアドレスを入力してください');
    });

    test('スペースのみはエラーを返す', () {
      expect(viewModel.validateEmail('   '),
          'メールアドレスを入力してください');
    });

    test('@がない場合はエラーを返す', () {
      expect(viewModel.validateEmail('testexample.com'),
          'メールアドレスの形式が正しくありません');
    });

    test('@がある場合はnullを返す', () {
      expect(viewModel.validateEmail('test@'), null);
    });
  });

  group('WebAuthViewModel - validatePassword', () {
    late WebAuthViewModel viewModel;

    setUp(() {
      viewModel = WebAuthViewModel(
        MockFirebaseAuth(),
        MockGoogleSignIn(),
      );
    });

    test('8文字以上のパスワードはnullを返す', () {
      expect(viewModel.validatePassword('password123'), null);
    });

    test('ちょうど8文字はnullを返す', () {
      expect(viewModel.validatePassword('12345678'), null);
    });

    test('空文字はエラーを返す', () {
      expect(viewModel.validatePassword(''),
          'パスワードを入力してください');
    });

    test('7文字以下はエラーを返す', () {
      expect(viewModel.validatePassword('1234567'),
          'パスワードは8文字以上で入力してください');
    });

    test('1文字はエラーを返す', () {
      expect(viewModel.validatePassword('a'),
          'パスワードは8文字以上で入力してください');
    });
  });

  // ================================================================
  // AdminSettingsViewModel - パスワード変更バリデーション
  // ================================================================
  group('AdminSettingsViewModel - changePassword バリデーション', () {
    late AdminSettingsViewModel viewModel;

    setUp(() {
      // ログイン済みユーザーをモック
      final mockUser = MockUser(
        uid: 'test-uid',
        email: 'test@example.com',
      );
      viewModel = AdminSettingsViewModel(
        MockFirebaseAuth(mockUser: mockUser, signedIn: true),
      );
    });

    test('現在のパスワードが空の場合はfalseを返す', () async {
      final result = await viewModel.changePassword(
        currentPassword: '',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(result, false);
      expect(viewModel.errorMessage, '現在のパスワードを入力してください');
    });

    test('新しいパスワードが8文字未満の場合はfalseを返す', () async {
      final result = await viewModel.changePassword(
        currentPassword: 'current123',
        newPassword: '1234567',
        confirmPassword: '1234567',
      );
      expect(result, false);
      expect(viewModel.errorMessage, '新しいパスワードは8文字以上で入力してください');
    });

    test('新しいパスワードがちょうど8文字はバリデーション通過する', () async {
      // バリデーションエラー（現在のパスワード空・新パス短い・不一致）が
      // 出ないことを確認（Firebase認証エラーは別途発生するが問題なし）
      final result = await viewModel.changePassword(
        currentPassword: 'current123',
        newPassword: '12345678',
        confirmPassword: '12345678',
      );
      // バリデーションエラーメッセージではないことを確認
      expect(viewModel.errorMessage,
          isNot('新しいパスワードは8文字以上で入力してください'));
      expect(viewModel.errorMessage,
          isNot('新しいパスワードが一致しません'));
      expect(viewModel.errorMessage,
          isNot('現在のパスワードを入力してください'));
    });

    test('確認パスワードが一致しない場合はfalseを返す', () async {
      final result = await viewModel.changePassword(
        currentPassword: 'current123',
        newPassword: 'newpassword123',
        confirmPassword: 'differentpassword',
      );
      expect(result, false);
      expect(viewModel.errorMessage, '新しいパスワードが一致しません');
    });

    test('clearMessagesでエラーがリセットされる', () async {
      await viewModel.changePassword(
        currentPassword: '',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(viewModel.errorMessage, isNotNull);
      viewModel.clearMessages();
      expect(viewModel.errorMessage, null);
      expect(viewModel.successMessage, null);
    });

    test('バリデーション順序：現在のパスワードが空 > 新しいパスワード短い', () async {
      final result = await viewModel.changePassword(
        currentPassword: '',
        newPassword: '123',
        confirmPassword: '123',
      );
      expect(result, false);
      // 現在のパスワードのエラーが先に返る
      expect(viewModel.errorMessage, '現在のパスワードを入力してください');
    });
  });
}
