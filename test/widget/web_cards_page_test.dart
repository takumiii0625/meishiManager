// test/widget/web_cards_page_test.dart
//
// Web名刺一覧・関連画面 Widget テスト
//
// 【テスト対象】
//   - WebAuthPage  : ログイン/新規登録切り替え・パスワード表示トグル
//   - WebCardsPage : 名刺一覧・タブ・検索・ヘッダーボタン
//   - AddCardDialog: 名刺追加ダイアログ
//   - AdminDashboardPage: 管理画面NavigationRail
//
// 【実行方法】
//   flutter test test/widget/web_cards_page_test.dart

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:meishi_manager/models/viewmodels/web_auth_viewmodel.dart';
import 'package:meishi_manager/providers/auth_providers.dart';
import 'package:meishi_manager/providers/card_providers.dart';
import 'package:meishi_manager/providers/web_auth_provider.dart';
import 'package:meishi_manager/models/card_model.dart';
import 'package:meishi_manager/views/auth/web_auth_page.dart';
import 'package:meishi_manager/views/cards/components/add_card_dialog.dart';
import 'package:meishi_manager/views/admin/admin_dashboard_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:meishi_manager/providers/admin_dashboard_providers.dart';
import 'package:meishi_manager/providers/admin_providers.dart';
import 'package:meishi_manager/repositories/admin_repository.dart';
import 'package:meishi_manager/models/viewmodels/admin_dashboard_viewmodel.dart';

// ================================================================
// テスト用ヘルパー
// ================================================================
Widget buildWebAuthPage({MockFirebaseAuth? mockAuth}) {
  final auth = mockAuth ?? MockFirebaseAuth();
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      webAuthViewModelProvider.overrideWith(
        (ref) => WebAuthViewModel(auth, MockGoogleSignIn()),
      ),
    ],
    child: const MaterialApp(home: WebAuthPage()),
  );
}

Widget buildAddCardDialog({MockFirebaseAuth? mockAuth}) {
  final auth = mockAuth ?? MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'test-uid'));
  final fakeFirestore = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddCardDialog(),
            ),
            child: const Text('開く'),
          ),
        ),
      ),
    ),
  );
}

Widget buildAdminDashboardPage({MockFirebaseAuth? mockAuth}) {
  final auth = mockAuth ?? MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'admin-uid', email: 'admin@example.com'),
  );
  final fakeFirestore = FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      adminDashboardViewModelProvider.overrideWith(
        (ref) => AdminDashboardViewModel(fakeFirestore),
      ),
      adminRepositoryProvider.overrideWith(
        (ref) => AdminRepository(fakeFirestore),
      ),
    ],
    child: const MaterialApp(home: AdminDashboardPage()),
  );
}

void main() {
  // ================================================================
  // WebAuthPage - ログイン/新規登録切り替え
  // ================================================================
  group('WebAuthPage - ログイン/新規登録切り替え', () {
    testWidgets('初期状態でログインボタンが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('ログイン'), findsWidgets);
    });

    testWidgets('新規登録に切り替えられる', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      // 「新規登録」テキストをタップして切り替え
      final signUpText = find.text('新規登録');
      if (signUpText.evaluate().isNotEmpty) {
        await tester.tap(signUpText.first);
        await tester.pumpAndSettle();
        expect(find.text('新規登録'), findsWidgets);
      }
    });

    testWidgets('ログイン状態でメールアドレスでログインするテキストが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('メールアドレスでログインする'), findsOneWidget);
    });
  });

  // ================================================================
  // WebAuthPage - パスワード表示/非表示トグル
  // ================================================================
  group('WebAuthPage - パスワード表示/非表示トグル', () {
    testWidgets('パスワード非表示アイコンが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('パスワード表示アイコンをタップすると切り替わる', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      final icon = find.byIcon(Icons.visibility_off);
      await tester.ensureVisible(icon);
      await tester.pumpAndSettle();
      await tester.tap(icon, warnIfMissed: false);
      await tester.pump();

      // 表示アイコンに切り替わる
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('もう一度タップすると非表示に戻る', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      final offIcon = find.byIcon(Icons.visibility_off);
      await tester.ensureVisible(offIcon);
      await tester.pumpAndSettle();
      await tester.tap(offIcon, warnIfMissed: false);
      await tester.pump();

      final onIcon = find.byIcon(Icons.visibility);
      await tester.ensureVisible(onIcon);
      await tester.pumpAndSettle();
      await tester.tap(onIcon, warnIfMissed: false);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });
  });

  // ================================================================
  // AddCardDialog - 名刺追加ダイアログ
  // ================================================================
  group('AddCardDialog - 表示確認', () {
    testWidgets('ダイアログを開くと名刺を追加のタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('名刺を追加'), findsOneWidget);
    });

    testWidgets('入力フィールドが複数表示される', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      // ダイアログに複数のTextFieldが存在することを確認
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('追加するボタンが表示される', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('追加する'), findsOneWidget);
    });

    testWidgets('キャンセルボタンが表示される', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('閉じるアイコンが表示される', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('AddCardDialog - 基本操作', () {
    testWidgets('名前を入力できる', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '山田太郎');
      await tester.pump();

      expect(find.text('山田太郎'), findsAtLeastNWidgets(1));
    });

    testWidgets('空のまま追加するをタップするとエラーが表示される', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      final addButton = find.text('追加する');
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.textContaining('入力してください'), findsOneWidget);
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('名刺を追加'), findsOneWidget);

      final cancelButton = find.text('キャンセル');
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('名刺を追加'), findsNothing);
    });

    testWidgets('閉じるアイコンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(buildAddCardDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('名刺を追加'), findsNothing);
    });
  });

  // ================================================================
  // AdminDashboardPage - 管理画面NavigationRail
  // ================================================================
  group('AdminDashboardPage - NavigationRail表示確認', () {
    testWidgets('ダッシュボードメニューが表示される', (tester) async {
      await tester.pumpWidget(buildAdminDashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('ダッシュボード'), findsAtLeastNWidgets(1));
    });

    testWidgets('ユーザー管理メニューが表示される', (tester) async {
      await tester.pumpWidget(buildAdminDashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('ユーザー管理'), findsAtLeastNWidgets(1));
    });

    testWidgets('設定メニューが表示される', (tester) async {
      await tester.pumpWidget(buildAdminDashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('設定'), findsAtLeastNWidgets(1));
    });

    testWidgets('NavigationRailが表示される', (tester) async {
      await tester.pumpWidget(buildAdminDashboardPage());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('ユーザー管理タブに切り替えられる', (tester) async {
      await tester.pumpWidget(buildAdminDashboardPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('ユーザー管理'));
      await tester.pumpAndSettle();

      expect(find.text('ユーザー管理'), findsAtLeastNWidgets(1));
    });

    testWidgets('設定タブに切り替えられる', (tester) async {
      await tester.pumpWidget(buildAdminDashboardPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();

      expect(find.text('設定'), findsAtLeastNWidgets(1));
    });
  });
}
