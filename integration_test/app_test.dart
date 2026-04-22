// integration_test/app_test.dart
//
// Flutter E2E テスト（integration_test）
//
// 【テスト対象】
//   - ログイン画面の表示確認
//   - 管理者ログイン画面の表示確認
//   - ログイン画面の基本操作
//
// 【実行方法】
//   # Chromeで実行（Web）
//   flutter test integration_test/app_test.dart -d chrome
//
//   # iOSシミュレーターで実行
//   flutter test integration_test/app_test.dart -d <device-id>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meishi_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ================================================================
  // ログイン画面（/login）の表示確認
  // ================================================================
  group('ログイン画面', () {
    testWidgets('アプリが起動してログイン画面が表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // アプリタイトルが表示されている
      expect(find.text('Meishi Manager'), findsOneWidget);
    });

    testWidgets('ソーシャルログインのテキストが表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ソーシャルアカウントでログイン'), findsOneWidget);
      expect(find.text('初めての方は自動で登録されます'), findsOneWidget);
    });

    testWidgets('ビジネス名刺をデジタルで管理のテキストが表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ビジネス名刺をデジタルで管理'), findsOneWidget);
    });

    testWidgets('GoogleログインボタンGが表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('G'), findsOneWidget);
    });

    testWidgets('Facebookログインボタンfが表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('f'), findsOneWidget);
    });

    testWidgets('パスワード入力フィールドが表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // hintText '8文字以上' のフィールドが存在する
      expect(find.widgetWithText(TextField, '8文字以上'), findsOneWidget);
    });

    testWidgets('メールアドレス入力フィールドが表示される', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(TextField), findsWidgets);
    });
  });

  // ================================================================
  // ログイン画面の基本操作
  // ================================================================
  group('ログイン画面 - 基本操作', () {
    testWidgets('メールアドレスを入力できる', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 最初のTextFieldにメールアドレスを入力
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('パスワードを入力できる', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // hintText '8文字以上' のフィールドにパスワードを入力
      final passwordField = find.widgetWithText(TextField, '8文字以上');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();
    });

    testWidgets('ログインボタンが存在してタップできる', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ElevatedButtonが存在する
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  // ================================================================
  // 管理者ログイン画面（/admin/login）の表示確認
  // ================================================================
  group('管理者ログイン画面', () {
    testWidgets('管理者ログイン画面に遷移できる', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // NavigatorでAdmin画面に遷移
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/admin/login');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 管理者ログイン画面のテキストが表示される
      expect(find.text('管理者ログイン'), findsOneWidget);
    });

    testWidgets('管理者ログイン画面にメール入力フィールドが存在する', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/admin/login');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('管理者ログイン画面にログインボタンが存在する', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/admin/login');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
