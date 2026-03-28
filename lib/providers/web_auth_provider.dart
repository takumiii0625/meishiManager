import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/viewmodels/web_auth_viewmodel.dart';

final _firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final _googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final webAuthViewModelProvider =
    ChangeNotifierProvider<WebAuthViewModel>((ref) {
  return WebAuthViewModel(
    ref.watch(_firebaseAuthProvider),
    ref.watch(_googleSignInProvider),
  );
});
