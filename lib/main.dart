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
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';

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
    return const MaterialApp(
      // AuthGate = ログイン状態によって画面を切り替えるWidget
      home: AuthGate(),
    );
  }
}
