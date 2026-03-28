import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/viewmodels/admin_dashboard_viewmodel.dart';
import 'card_providers.dart'; // firestoreProvider を再利用

final adminDashboardViewModelProvider =
    Provider<AdminDashboardViewModel>((ref) {
  return AdminDashboardViewModel(ref.watch(firestoreProvider));
});

final dashboardUsersStreamProvider =
    StreamProvider<QuerySnapshot>((ref) {
  return ref.watch(adminDashboardViewModelProvider).watchUsers();
});

final dashboardAccessLogsStreamProvider =
    StreamProvider<QuerySnapshot>((ref) {
  return ref
      .watch(adminDashboardViewModelProvider)
      .watchRecentAccessLogs();
});
