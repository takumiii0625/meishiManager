// test/widget/web_auth_page_test.dart
//
// Web認証画面 Widget テスト
//
// 【テスト対象】
//   - WebAuthPage  : ログイン画面のUI表示・基本操作
//   - AdminLoginPage : 管理者ログイン画面のUI表示・基本操作
//
// 【実行方法】
//   flutter test test/widget/web_auth_page_test.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:meishi_manager/providers/auth_providers.dart';
import 'package:meishi_manager/providers/web_auth_provider.dart';
import 'package:meishi_manager/models/viewmodels/web_auth_viewmodel.dart';
import 'package:meishi_manager/views/auth/admin_login_page.dart';
import 'package:meishi_manager/views/auth/web_auth_page.dart';

// ================================================================
// テスト用ヘルパー：MockFirebaseAuthをProviderに注入してWidgetを起動
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
    child: const MaterialApp(
      home: WebAuthPage(),
    ),
  );
}

Widget buildAdminLoginPage({MockFirebaseAuth? mockAuth}) {
  final auth = mockAuth ?? MockFirebaseAuth();
  return ProviderScope(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
    ],
    child: const MaterialApp(
      home: AdminLoginPage(),
    ),
  );
}

void main() {
  // ================================================================
  // WebAuthPage - ログイン画面 表示確認
  // ================================================================
  group('WebAuthPage - 表示確認', () {
    testWidgets('Meishi Manager のタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('Meishi Manager'), findsOneWidget);
    });

    testWidgets('ビジネス名刺をデジタルで管理 のテキストが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('ビジネス名刺をデジタルで管理'), findsOneWidget);
    });

    testWidgets('ソーシャルアカウントでログイン のテキストが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('ソーシャルアカウントでログイン'), findsOneWidget);
    });

    testWidgets('初めての方は自動で登録されます のテキストが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('初めての方は自動で登録されます'), findsOneWidget);
    });

    testWidgets('Googleログインボタン G が表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('G'), findsOneWidget);
    });

    testWidgets('Facebookログインボタン f が表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.text('f'), findsOneWidget);
    });

    testWidgets('TextFieldが複数表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('パスワード入力フィールドが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '8文字以上'), findsOneWidget);
    });

    testWidgets('ElevatedButtonが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  // ================================================================
  // WebAuthPage - 基本操作
  // ================================================================
  group('WebAuthPage - 基本操作', () {
    testWidgets('メールアドレスを入力できる', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('パスワードを入力できる', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, '8文字以上');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // obscureTextなので入力値は直接確認できないが例外が出ないことを確認
    });

    testWidgets('空のままログインボタンをタップするとエラーが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      // ボタンが画面外の場合はスクロールして表示
      final loginButton = find.byType(ElevatedButton).first;
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('入力してください'),
        findsOneWidget,
      );
    });

    testWidgets('不正なメールアドレスを入力するとエラーが表示される', (tester) async {
      await tester.pumpWidget(buildWebAuthPage());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'invalid-email');
      await tester.pump();

      final loginButton = find.byType(ElevatedButton).first;
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('形式が正しくありません'),
        findsOneWidget,
      );
    });
  });

  // ================================================================
  // AdminLoginPage - 管理者ログイン画面 表示確認
  // ================================================================
  group('AdminLoginPage - 表示確認', () {
    testWidgets('Meishi Manager のタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Meishi Manager'), findsOneWidget);
    });

    testWidgets('管理者アカウントでログイン のテキストが表示される', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('管理者アカウントでログイン'), findsOneWidget);
    });

    testWidgets('TextFieldが2つ表示される', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('ログインボタンが表示される', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ログイン ボタンのテキストが表示される', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('ログイン'), findsOneWidget);
    });
  });

  // ================================================================
  // AdminLoginPage - 基本操作
  // ================================================================
  group('AdminLoginPage - 基本操作', () {
    testWidgets('メールアドレスを入力できる', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'admin@example.com');
      await tester.pump();

      // EditableTextとTextの両方にマッチするためfindsAtLeastNWidgets(1)を使用
      expect(find.text('admin@example.com'), findsAtLeastNWidgets(1));
    });

    testWidgets('空のままログインボタンをタップしてもクラッシュしない', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // クラッシュせずに画面が表示されていることを確認
      expect(find.text('Meishi Manager'), findsOneWidget);
    });

    testWidgets('メールとパスワードを入力できる', (tester) async {
      await tester.pumpWidget(buildAdminLoginPage());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'admin@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      expect(find.text('admin@example.com'), findsAtLeastNWidgets(1));
    });
  });
}
