import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WebAuthViewModel extends ChangeNotifier {
  WebAuthViewModel(this._auth, this._googleSignIn);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  bool isLogin = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleMode() {
    isLogin = !isLogin;
    errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    errorMessage = msg;
    notifyListeners();
  }

  // 管理者かどうかチェック（管理者ならサインアウトしてエラー）
  Future<bool> _checkNotAdmin(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = (doc.data()?['role'] as String?) ?? 'user';
      if (role == 'admin') {
        await _auth.signOut();
        _setError('管理者アカウントです。管理者ログインページからログインしてください');
        return false;
      }
    } catch (_) {}
    return true;
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) return null;

      // 管理者はユーザーログイン画面からログインできない
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = (doc.data()?['role'] as String?) ?? 'user';
      if (role == 'admin') {
        await _auth.signOut();
        _setError('管理者アカウントです。管理者ログインページからログインしてください');
        return null;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      _setError(_emailErrorMessage(e.code));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String company = '',
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) return null;

      // Firestoreにユーザー情報を保存
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email.trim(),
        'company': company,
        'role': 'user',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      _setError(_emailErrorMessage(e.code));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      User? user;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final result = await _auth.signInWithPopup(provider);
        user = result.user;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _setLoading(false);
          return null;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        user = result.user;
      }
      if (user == null) return null;
      if (!await _checkNotAdmin(user)) return null;
      return user;
    } on FirebaseAuthException catch (e) {
      _setError(_emailErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('予期せぬエラーが発生しました');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------------------------------------------
  // パスワードリセットメール送信
  // ----------------------------------------------------------------
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ----------------------------------------------------------------
  // Twitterログイン
  // ----------------------------------------------------------------
  Future<User?> signInWithTwitter() async {
    _setLoading(true);
    _setError(null);
    try {
      final provider = TwitterAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      final user = result.user;
      if (user == null) return null;
      if (!await _checkNotAdmin(user)) return null;
      return user;
    } on FirebaseAuthException catch (e) {
      _setError(_emailErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('Twitterログインに失敗しました');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------------------------------------------
  // Facebookログイン
  // Web: signInWithPopup / モバイル: flutter_facebook_auth経由
  // account-exists-with-different-credential の場合は既存アカウントにリンク
  // ----------------------------------------------------------------
  Future<User?> signInWithFacebook() async {
    _setLoading(true);
    _setError(null);
    try {
      User? user;
      if (kIsWeb) {
        final provider = FacebookAuthProvider();
        final result = await _auth.signInWithPopup(provider);
        user = result.user;
      } else {
        final loginResult = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );
        if (loginResult.status != LoginStatus.success) {
          _setLoading(false);
          return null;
        }
        final credential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );
        final result = await _auth.signInWithCredential(credential);
        user = result.user;
      }
      if (user == null) return null;
      if (!await _checkNotAdmin(user)) return null;
      return user;
    } on FirebaseAuthException catch (e) {
      // 同じメールアドレスが別プロバイダで登録済みの場合
      if (e.code == 'account-exists-with-different-credential') {
        try {
          final googleProvider = GoogleAuthProvider();
          final googleResult = await _auth.signInWithPopup(googleProvider);
          final facebookCredential = e.credential;
          if (facebookCredential != null) {
            await googleResult.user?.linkWithCredential(facebookCredential);
          }
          final user = googleResult.user;
          if (user == null) return null;
          if (!await _checkNotAdmin(user)) return null;
          _setError('Googleアカウントでログインし、Facebookもリンクしました');
          return user;
        } catch (_) {
          _setError('同じメールアドレスのアカウントがあります。Googleでログインしてください');
          return null;
        }
      }
      _setError(_emailErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('Facebookログインに失敗しました');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'メールアドレスを入力してください';
    if (!email.contains('@')) return 'メールアドレスの形式が正しくありません';
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return 'パスワードを入力してください';
    if (password.length < 8) return 'パスワードは8文字以上で入力してください';
    return null;
  }

  String _emailErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスはすでに使用されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードが弱すぎます。6文字以上にしてください';
      case 'too-many-requests':
        return 'ログイン試行回数が多すぎます。しばらくしてからお試しください';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました。接続を確認してください';
      case 'popup-closed-by-user':
        return 'ログインがキャンセルされました';
      case 'popup-blocked':
        return 'ポップアップがブロックされました。ブラウザの設定を確認してください';
      default:
        return 'エラーが発生しました ($code)';
    }
  }
}
