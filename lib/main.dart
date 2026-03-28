import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';
import 'providers/auth_providers.dart';
import 'views/auth/admin_login_page.dart';
import 'views/auth/web_auth_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/admin_users_page.dart';
import 'views/cards/web_cards_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meishi Manager',
      home: kIsWeb ? const WebRootPage() : const AuthGate(),
      routes: {
        '/login':           (context) => const WebAuthPage(),
        '/admin/login':     (context) => const AdminLoginPage(),
        '/admin/dashboard': (context) => const AdminDashboardPage(),
        '/admin/users':     (context) => const AdminUsersPage(),
        '/home':            (context) => kIsWeb ? const WebRootPage() : const AuthGate(),
      },
    );
  }
}

// ----------------------------------------------------------------
// Webの起点：ログイン状態とroleで振り分け
// ----------------------------------------------------------------
class WebRootPage extends ConsumerWidget {
  const WebRootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const WebAuthPage(),
      data: (user) {
        if (user == null) return const WebAuthPage();
        return _RoleRouter(uid: user.uid);
      },
    );
  }
}

// ----------------------------------------------------------------
// roleを確認してルーティング
// ----------------------------------------------------------------
class _RoleRouter extends StatelessWidget {
  const _RoleRouter({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'] as String? ?? 'user';
          if (role == 'admin') {
            return const AdminDashboardPage();
          }
        }
        return const WebCardsPage();
      },
    );
  }
}
