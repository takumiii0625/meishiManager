import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// ログイン状態の監視
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// 匿名ログイン（未ログインなら匿名で入る）
final anonymousSignInProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);

  final current = auth.currentUser;
  if (current != null) return current;

  final cred = await auth.signInAnonymously();
  final user = cred.user;
  if (user == null) throw StateError('Anonymous sign-in returned null user');
  return user;
});

/// uid（ログイン済みのユーザー）
/// Web: anonymousSignInを使わないのでauthStateChangesを直接参照
/// モバイル: AuthGateでanonymousSignInを発火済みなのでそちらを利用
final uidProvider = Provider<String>((ref) {
  final user = ref.watch(authStateChangesProvider).maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );
  return user?.uid ?? '';
});

class EmailAuthParams {
  EmailAuthParams({required this.email, required this.password});
  final String email;
  final String password;
}

/// 匿名ユーザーに Email/Password をリンクして "同じuidのまま昇格"
final linkEmailProvider =
    FutureProvider.autoDispose.family<User, EmailAuthParams>((ref, params) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) throw StateError('No current user');

  final credential = EmailAuthProvider.credential(
    email: params.email.trim(),
    password: params.password,
  );

  final result = await user.linkWithCredential(credential);
  final linked = result.user;
  if (linked == null) throw StateError('linkWithCredential returned null user');
  return linked;
});

/// Email/Password 新規登録（新しいuidになる）
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

/// Email/Password ログイン
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

/// ログアウト
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
