import 'package:meishi_manager/views/admin/admin_login_page.dart';
import 'package:meishi_manager/views/admin/admin_dashboard_page.dart';
import 'package:meishi_manager/views/admin/admin_users_page.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';

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
      // ✅ Webならログイン画面、それ以外（スマホ）ならAuthGateを表示
      home: kIsWeb ? const AdminLoginPage() : const AuthGate(),
      routes: {
        '/admin/login': (context) => const AdminLoginPage(),
        '/admin/dashboard': (context) => const AdminDashboardPage(),
        '/admin/users': (context) => const AdminUsersPage(),
      },
    );
  }
}