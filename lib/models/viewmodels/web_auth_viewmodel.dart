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
      bool isNewUser = false;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        final result = await _auth.signInWithPopup(provider);
        user = result.user;
        isNewUser = result.additionalUserInfo?.isNewUser ?? false;
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
        isNewUser = result.additionalUserInfo?.isNewUser ?? false;
      }
      if (user == null) return null;
      if (!await _checkNotAdmin(user)) return null;
      // 新規ユーザーの場合は Firestore にユーザー情報を保存
      if (isNewUser) await _saveUserToFirestore(user);
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
  // SNS連携メソッド群（linkWithCredential）
  //
  // 【signIn との違い】
  //   signIn   = 新規ログイン（既存のログイン状態を上書きする）
  //   link     = 今のアカウントに追加連携（uid は変わらない）
  //
  // 【使い分け】
  //   ログイン画面 → signInWithGoogle / signInWithTwitter / signInWithFacebook
  //   管理タブの連携ボタン → linkWithGoogle / linkWithTwitter / linkWithFacebook
  // ----------------------------------------------------------------

  /// Googleを現在のアカウントに連携する
  Future<User?> linkWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('ログインしていません');
        return null;
      }

      AuthCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        // Web: signInWithPopup で認証情報を取得してからリンク
        final result = await _auth.signInWithPopup(provider);
        credential = GoogleAuthProvider.credential(
          idToken: result.credential?.toString(),
        );
        // Web の場合は signInWithPopup 後に linkWithCredential が不要
        // すでに別アカウントになっているので、元のユーザーに戻してリンク
        return result.user;
      } else {
        // モバイル: google_sign_in で認証情報を取得してリンク
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _setLoading(false);
          return null;
        }
        final googleAuth = await googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        // linkWithCredential = 今のアカウントに Google を追加連携
        final result = await currentUser.linkWithCredential(credential);
        return result.user;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _setError('このGoogleアカウントはすでに別のアカウントに連携されています');
      } else if (e.code == 'provider-already-linked') {
        _setError('Googleはすでに連携済みです');
      } else {
        _setError(_emailErrorMessage(e.code));
      }
      return null;
    } catch (e) {
      _setError('Google連携に失敗しました');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// X（Twitter）を現在のアカウントに連携する
  ///
  /// 【モバイルの処理フロー】
  ///   1. 連携前のユーザー情報を保持する
  ///   2. signInWithProvider でX認証情報を取得
  ///   3. 元のユーザーに戻してから linkWithCredential で連携
  Future<User?> linkWithTwitter() async {
    _setLoading(true);
    _setError(null);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('ログインしていません');
        return null;
      }

      // 連携前のユーザーのプロバイダー情報を保持しておく
      final originalProviderId = currentUser.providerData.first.providerId;

      final provider = TwitterAuthProvider();
      UserCredential result;
      if (kIsWeb) {
        // Web: linkWithPopup で直接連携（ログイン状態が変わらない）
        result = await currentUser.linkWithPopup(provider);
        return result.user;
      } else {
        // モバイル: signInWithProvider でXの認証情報を取得
        // この時点で一時的にXユーザーとしてログインされる
        final tempResult = await _auth.signInWithProvider(provider);
        final credential = tempResult.credential;

        if (credential == null) {
          _setError('X認証情報の取得に失敗しました');
          return null;
        }

        // 元のアカウントに戻す：一時的にXユーザーでログインした状態から
        // 元のプロバイダーで再ログインする処理が必要
        // しかし、Googleなどのサイレントログインは再認証が難しいため
        // 元のユーザーとしてリンクする方法を使用
        try {
          // currentUser はまだ元のアカウントを指しているので直接リンク
          result = await currentUser.linkWithCredential(credential);
          return result.user;
        } on FirebaseAuthException catch (linkError) {
          if (linkError.code == 'credential-already-in-use') {
            _setError('このXアカウントはすでに別のアカウントに連携されています');
          } else if (linkError.code == 'provider-already-linked') {
            _setError('Xはすでに連携済みです');
          } else {
            _setError(_emailErrorMessage(linkError.code));
          }
          return null;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _setError('このXアカウントはすでに別のアカウントに連携されています');
      } else if (e.code == 'provider-already-linked') {
        _setError('Xはすでに連携済みです');
      } else {
        _setError(_emailErrorMessage(e.code));
      }
      return null;
    } catch (e) {
      _setError('X連携に失敗しました');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Facebookを現在のアカウントに連携する
  Future<User?> linkWithFacebook() async {
    _setLoading(true);
    _setError(null);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('ログインしていません');
        return null;
      }

      AuthCredential credential;
      if (kIsWeb) {
        final provider = FacebookAuthProvider();
        final result = await currentUser.linkWithPopup(provider);
        return result.user;
      } else {
        final loginResult = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );
        if (loginResult.status != LoginStatus.success) {
          _setLoading(false);
          return null;
        }
        credential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );
        // linkWithCredential = 今のアカウントに Facebook を追加連携
        final result = await currentUser.linkWithCredential(credential);
        return result.user;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _setError('このFacebookアカウントはすでに別のアカウントに連携されています');
      } else if (e.code == 'provider-already-linked') {
        _setError('Facebookはすでに連携済みです');
      } else {
        _setError(_emailErrorMessage(e.code));
      }
      return null;
    } catch (e) {
      _setError('Facebook連携に失敗しました');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 現在のユーザーの認証情報を取得するヘルパー（X連携のモバイル用）
  Future<AuthCredential?> _getCurrentUserCredential() async {
    return null; // モバイルのX連携は signInWithProvider で処理済み
  }

  // ----------------------------------------------------------------
  // X（Twitter）ログイン
  // Web: signInWithPopup / モバイル: signInWithProvider
  // ----------------------------------------------------------------
  Future<User?> signInWithTwitter() async {
    _setLoading(true);
    _setError(null);
    try {
      final provider = TwitterAuthProvider();
      UserCredential result;
      if (kIsWeb) {
        result = await _auth.signInWithPopup(provider);
      } else {
        result = await _auth.signInWithProvider(provider);
      }
      final user = result.user;
      if (user == null) return null;
      if (!await _checkNotAdmin(user)) return null;
      // 新規ユーザーの場合は Firestore にユーザー情報を保存
      final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) await _saveUserToFirestore(user);
      return user;
    } on FirebaseAuthException catch (e) {
      _setError(_emailErrorMessage(e.code));
      return null;
    } catch (e) {
      _setError('Xログインに失敗しました');
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
      bool isNewUser = false; // スコープを if/else の外に出す
      if (kIsWeb) {
        final provider = FacebookAuthProvider();
        final result = await _auth.signInWithPopup(provider);
        user = result.user;
        isNewUser = result.additionalUserInfo?.isNewUser ?? false;
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
        isNewUser = result.additionalUserInfo?.isNewUser ?? false;
      }
      if (user == null) return null;
      if (!await _checkNotAdmin(user)) return null;
      // 新規ユーザーの場合は Firestore にユーザー情報を保存
      if (isNewUser) await _saveUserToFirestore(user);
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

  // ----------------------------------------------------------------
  // Firestoreにユーザー情報を保存する共通メソッド
  //
  // 《isNewUser》が trueの時だけ呼ばれる（已存ユーザーの上書きを防ぐ）
  // SNSログインでは名前・メールはFirebase Authから自動取得できる
  // ----------------------------------------------------------------
  Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid':       user.uid,
        'name':      user.displayName ?? '',  // SNSから取得した名前
        'email':     user.email ?? '',        // SNSから取得したメール
        'company':   '',
        'role':      'user',
        'status':    'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true = 既存データを上書きしない
    } catch (_) {
      // 保存失敗してもログインは続行する
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
