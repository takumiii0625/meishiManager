import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminSettingsViewModel extends ChangeNotifier {
  AdminSettingsViewModel(this._auth);

  final FirebaseAuth _auth;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage  = null;
    successMessage = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // 現在のユーザー情報
  // ----------------------------------------------------------------
  User? get currentUser => _auth.currentUser;

  // ----------------------------------------------------------------
  // パスワード変更
  // ----------------------------------------------------------------
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // バリデーション
    if (currentPassword.isEmpty) {
      errorMessage = '現在のパスワードを入力してください';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 8) {
      errorMessage = '新しいパスワードは8文字以上で入力してください';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      errorMessage = '新しいパスワードが一致しません';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    errorMessage   = null;
    successMessage = null;

    try {
      final user = _auth.currentUser!;

      // 再認証
      final credential = EmailAuthProvider.credential(
        email:    user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // パスワード更新
      await user.updatePassword(newPassword);

      successMessage = 'パスワードを変更しました';
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = '現在のパスワードが正しくありません';
      } else {
        errorMessage = 'エラーが発生しました（${e.code}）';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------------------------------------------
  // ログアウト
  // ----------------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
