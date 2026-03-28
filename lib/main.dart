// ============================================================
// main.dart
// アプリのエントリーポイント（一番最初に実行されるファイル）
//
// 【起動の流れ】
//   1. WidgetsFlutterBinding.ensureInitialized()
//      → Flutterのエンジンを初期化する（Firebaseより先に呼ぶ必要がある）
//   2. Firebase.initializeApp()
//      → Firebaseに接続する（Firestore・Auth・Storageが使えるようになる）
//   3. runApp()
//      → 画面の描画を開始する
//
// 【ProviderScope とは？】
//   Riverpod の状態管理を使うために、アプリ全体を ProviderScope で包む。
//   これがないと ref.watch() などが使えない。
//
// 【kIsWeb による画面振り分け】
//   kIsWeb = Flutter が Web として動いているかどうかを判定する定数
//   Web（管理者用）→ AdminLoginPage（管理者ログイン画面）
//   スマホ（一般ユーザー用）→ AuthGate（通常のログイン処理）
// ============================================================

import 'package:flutter/foundation.dart'; // kIsWeb を使うために必要
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';
import 'views/admin/admin_login_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/admin_users_page.dart';

/// アプリのエントリーポイント
/// async = 非同期処理（Firebaseの初期化が終わってから次へ進む）
Future<void> main() async {
  // Flutterエンジンの初期化（非同期処理を使う前に必ず呼ぶ）
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseを初期化（firebase_options.dart に設定値が入っている）
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // アプリを起動
  // ProviderScope = Riverpodの状態管理をアプリ全体で使えるようにするラッパー
  runApp(const ProviderScope(child: MyApp()));
}

/// アプリのルートWidget
/// StatelessWidget = 内部に状態を持たないシンプルなWidget
class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meishi Manager',
      // kIsWeb = true（Web）→ 管理者ログイン画面
      // kIsWeb = false（スマホ）→ 通常の AuthGate
      home: kIsWeb ? const AdminLoginPage() : const AuthGate(),
      // admin系画面へのルート定義
      // Navigator.pushNamed(context, '/admin/dashboard') のように使う
      routes: {
        '/admin/login':     (context) => const AdminLoginPage(),
        '/admin/dashboard': (context) => const AdminDashboardPage(),
        '/admin/users':     (context) => const AdminUsersPage(),
      },
    );
  }
}