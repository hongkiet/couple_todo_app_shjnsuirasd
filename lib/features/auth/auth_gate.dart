import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Nếu user chưa trong couple => chuyển tới /pair, ngược lại /home (handled inside pages)
      return const _RouteDecider();
    }

    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final s = Supabase.instance.client.auth.currentSession;
        if (s != null) return const _RouteDecider();
        return const SignInPage();
      },
    );
  }
}

class _RouteDecider extends StatelessWidget {
  const _RouteDecider();

  Future<bool> _hasCouple() async {
    try {
      final supa = Supabase.instance.client;
      final response = await supa
          .from('couple_members')
          .select('couple_id')
          .limit(1);
      return (response.isNotEmpty);
    } catch (e) {
      // Log error để debug
      debugPrint('[AuthGate] Error checking couple: $e');
      // Nếu có lỗi, giả sử user chưa có couple để chuyển về pairing page
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCouple(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('[AuthGate] FutureBuilder error: ${snapshot.error}');
          // Nếu có lỗi, chuyển về pairing page
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.go('/pair'),
          );
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.go('/home'),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.go('/pair'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
