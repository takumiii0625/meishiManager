import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'views/home/home_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★未ログインなら匿名ログインを発火
    ref.watch(anonymousSignInProvider);

    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) {
        if (user == null) {
          // 匿名ログインがまだ完了してない瞬間だけここに入る
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 匿名でもOK → BottomNavへ
        return const HomeShell();
      },
    );
  }
}
