import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/viewmodels/admin_settings_viewmodel.dart';
import 'auth_providers.dart'; // firebaseAuthProvider を再利用

final adminSettingsViewModelProvider =
    ChangeNotifierProvider<AdminSettingsViewModel>((ref) {
  return AdminSettingsViewModel(ref.watch(firebaseAuthProvider));
});
