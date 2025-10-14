import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_gate.dart';
import '../features/tasks/ui/home_page.dart';
import '../features/couple/pairing_page.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AuthGate()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/pair', builder: (_, __) => const PairingPage()),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Couple To-Do',
      routerConfig: _router,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      debugShowCheckedModeBanner: false,
    );
  }
}
