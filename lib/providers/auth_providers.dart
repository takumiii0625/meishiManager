// ============================================================
// auth_providers.dart
// Firebase Auth に関する Riverpod Provider をまとめたファイル
//
// 【このファイルの役割】
//   ログイン・ログアウト・ユーザー情報取得に使う Provider を定義する。
//   画面からは ref.watch(uidProvider) のように呼ぶだけで使える。
//
// 【Provider の種類（復習）】
//   Provider        = 変化しない値を提供する（FirebaseAuth インスタンスなど）
//   StreamProvider  = リアルタイムで変化する値を監視する（ログイン状態など）
//   FutureProvider  = 非同期処理を1回実行する（ログイン・ログアウトなど）
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// FirebaseAuth のインスタンスを提供する Provider
///
/// FirebaseAuth.instance を直接呼ぶのではなく、
/// Provider 経由にすることでテスト時に差し替えがしやすくなる。
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firebase Auth のログイン状態をリアルタイムで監視する Provider
///
/// authStateChanges() = ログイン・ログアウトが起きるたびに新しい値を流す Stream
/// User? = ログイン中は User オブジェクト、未ログインは null
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// 匿名ログインを実行する Provider
///
/// 【匿名ログインとは？】
///   メールアドレスやパスワードなしで Firebase Auth にログインする方法。
///   ユーザーが意識せずにアプリを使い始められる。
///   すでにログイン済みなら何もせずに現在のユーザーを返す。
final anonymousSignInProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);

  // すでにログイン済みなら、そのユーザーをそのまま返す（再ログイン不要）
  final current = auth.currentUser;
  if (current != null) return current;

  // 未ログインなら匿名ログインを実行
  final cred = await auth.signInAnonymously();
  final user = cred.user;
  // user が null になることはないはずだが、念のためエラーを投げる
  if (user == null) throw StateError('Anonymous sign-in returned null user');
  return user;
});

/// uid（ログイン済みのユーザー）
/// Web: anonymousSignInを使わないのでauthStateChangesを直接参照
/// モバイル: AuthGateでanonymousSignInを発火済みなのでそちらを利用
final uidProvider = Provider<String>((ref) {
  // maybeWhen = data の場合だけ値を取り出し、それ以外は orElse を返す
  final user = ref.watch(authStateChangesProvider).maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );
  // user が null（未ログイン）なら空文字を返す
  return user?.uid ?? '';
});

/// メール認証用のパラメータをまとめたクラス
///
/// FutureProvider.family には引数を1つしか渡せないため、
/// 複数の引数（email と password）をこのクラスにまとめて渡す。
class EmailAuthParams {
  EmailAuthParams({required this.email, required this.password});
  final String email;
  final String password;
}

/// 匿名ユーザーにメール/パスワードをリンクして「昇格」する Provider
///
/// 【昇格とは？】
///   匿名ユーザーのまま使っていたデータを、
///   メールアドレスと紐づけることで「正規ユーザー」にすること。
///   uid は変わらないので、今まで登録した名刺がそのまま使える。
///
/// autoDispose = 画面が閉じたら自動でリセットされる
/// family = 引数（EmailAuthParams）を受け取れる
final linkEmailProvider =
    FutureProvider.autoDispose.family<User, EmailAuthParams>((ref, params) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) throw StateError('No current user');

  // EmailAuthProvider.credential = メール認証情報を作成
  final credential = EmailAuthProvider.credential(
    email: params.email.trim(), // trim() = 前後の空白を除去
    password: params.password,
  );

  // linkWithCredential = 匿名ユーザーにメール認証を紐づける
  final result = await user.linkWithCredential(credential);
  final linked = result.user;
  if (linked == null) throw StateError('linkWithCredential returned null user');
  return linked;
});

/// メール/パスワードで新規登録する Provider
///
/// 注意: 新規登録すると新しい uid が発行される。
///       匿名ユーザーとは別のアカウントになる。
///       既存データを引き継ぐには linkEmailProvider を使うこと。
final signUpWithEmailProvider =
    FutureProvider.autoDispose.family<User, EmailAuthParams>((ref, params) async {
  final auth = ref.watch(firebaseAuthProvider);
  final cred = await auth.createUserWithEmailAndPassword(
    email: params.email.trim(),
    password: params.password,
  );
  final user = cred.user;
  if (user == null) throw StateError('createUserWithEmailAndPassword returned null user');
  return user;
});

/// メール/パスワードでログインする Provider
final signInWithEmailProvider =
    FutureProvider.autoDispose.family<User, EmailAuthParams>((ref, params) async {
  final auth = ref.watch(firebaseAuthProvider);
  final cred = await auth.signInWithEmailAndPassword(
    email: params.email.trim(),
    password: params.password,
  );
  final user = cred.user;
  if (user == null) throw StateError('signInWithEmailAndPassword returned null user');
  return user;
});

/// ログアウトする Provider
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  await auth.signOut();
});

// ----------------------------------------------------------------
// Google認証（Web対応）
// ----------------------------------------------------------------

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

/// Googleログイン
final signInWithGoogleProvider =
    FutureProvider.autoDispose<User>((ref) async {
  final googleSignIn = ref.watch(googleSignInProvider);
  final auth = ref.watch(firebaseAuthProvider);

  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) throw StateError('Google sign-in was cancelled');

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final result = await auth.signInWithCredential(credential);
  final user = result.user;
  if (user == null) throw StateError('Google sign-in returned null user');
  return user;
});
