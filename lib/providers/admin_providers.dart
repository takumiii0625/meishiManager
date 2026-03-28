import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/viewmodels/admin_users_viewmodel.dart';
import '../repositories/admin_repository.dart';
import 'card_providers.dart'; // firestoreProvider を再利用

// ----------------------------------------------------------------
// Repository
// ----------------------------------------------------------------
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(firestoreProvider));
});

// ----------------------------------------------------------------
// ViewModel
// ----------------------------------------------------------------
final adminUsersViewModelProvider =
    ChangeNotifierProvider<AdminUsersViewModel>((ref) {
  return AdminUsersViewModel(ref.watch(adminRepositoryProvider));
});

// ----------------------------------------------------------------
// ユーザー一覧ストリーム
// ----------------------------------------------------------------
final adminUsersStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return ref.watch(adminRepositoryProvider).watchUsers();
});

// ----------------------------------------------------------------
// 検索・フィルター状態
// ----------------------------------------------------------------
final adminSearchQueryProvider = StateProvider<String>((ref) => '');
final adminStatusFilterProvider = StateProvider<String>((ref) => 'all');

// ----------------------------------------------------------------
// ユーザー作成パラメータ
// ----------------------------------------------------------------
class CreateUserParams {
  CreateUserParams({
    required this.name,
    required this.email,
    required this.password,
    required this.company,
    required this.role,
  });
  final String name;
  final String email;
  final String password;
  final String company;
  final String role;
}

final createUserProvider =
    FutureProvider.autoDispose.family<void, CreateUserParams>(
  (ref, params) async {
    await ref.read(adminUsersViewModelProvider).createUser(
          name: params.name,
          email: params.email,
          password: params.password,
          company: params.company,
          role: params.role,
        );
  },
);

// ----------------------------------------------------------------
// ユーザー編集パラメータ
// ----------------------------------------------------------------
class UpdateUserParams {
  UpdateUserParams({
    required this.userId,
    required this.name,
    required this.email,
    required this.company,
    required this.status,
    required this.role,
    required this.oldStatus,
  });
  final String userId;
  final String name;
  final String email;
  final String company;
  final String status;
  final String role;
  final String oldStatus;
}

final updateUserProvider =
    FutureProvider.autoDispose.family<void, UpdateUserParams>(
  (ref, params) async {
    await ref.read(adminUsersViewModelProvider).updateUser(
          userId: params.userId,
          name: params.name,
          email: params.email,
          company: params.company,
          status: params.status,
          role: params.role,
          oldStatus: params.oldStatus,
        );
  },
);

// ----------------------------------------------------------------
// ユーザー削除パラメータ
// ----------------------------------------------------------------
class DeleteUserParams {
  DeleteUserParams({required this.userId, required this.userName});
  final String userId;
  final String userName;
}

final deleteUserProvider =
    FutureProvider.autoDispose.family<void, DeleteUserParams>(
  (ref, params) async {
    await ref.read(adminUsersViewModelProvider).deleteUser(
          userId: params.userId,
          userName: params.userName,
        );
  },
);

// ----------------------------------------------------------------
// 名刺一覧ストリーム
// ----------------------------------------------------------------
final adminBusinessCardsStreamProvider =
    StreamProvider.autoDispose.family<QuerySnapshot, String>(
  (ref, userId) {
    return ref.watch(adminRepositoryProvider).watchBusinessCards(userId);
  },
);

// ----------------------------------------------------------------
// アクセスログストリーム
// ----------------------------------------------------------------
final adminAccessLogsStreamProvider =
    StreamProvider.autoDispose.family<QuerySnapshot, String>(
  (ref, targetUserId) {
    return ref.watch(adminRepositoryProvider).watchAccessLogs(targetUserId);
  },
);

// ----------------------------------------------------------------
// アクセスログ記録パラメータ
// ----------------------------------------------------------------
class WriteAccessLogParams {
  WriteAccessLogParams({
    required this.targetUserId,
    required this.action,
    this.detail = '',
  });
  final String targetUserId;
  final String action;
  final String detail;
}

final writeAccessLogProvider =
    FutureProvider.autoDispose.family<void, WriteAccessLogParams>(
  (ref, params) async {
    await ref.read(adminUsersViewModelProvider).writeAccessLog(
          targetUserId: params.targetUserId,
          action: params.action,
          detail: params.detail,
        );
  },
);
