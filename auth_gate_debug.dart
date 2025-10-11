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

class _RouteDecider extends StatefulWidget {
  const _RouteDecider();

  @override
  State<_RouteDecider> createState() => _RouteDeciderState();
}

class _RouteDeciderState extends State<_RouteDecider> {
  bool _isLoading = true;
  String? _error;
  bool? _hasCouple;

  @override
  void initState() {
    super.initState();
    _checkCouple();
  }

  Future<void> _checkCouple() async {
    try {
      debugPrint('[AuthGate] Starting couple check...');
      
      final supa = Supabase.instance.client;
      final userId = supa.auth.currentUser?.id;
      debugPrint('[AuthGate] Current user ID: $userId');
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supa
          .from('couple_members')
          .select('couple_id')
          .limit(1);
      
      debugPrint('[AuthGate] Query response: $response');
      
      setState(() {
        _hasCouple = response.isNotEmpty;
        _isLoading = false;
      });
      
      // Navigate after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasCouple == true) {
          debugPrint('[AuthGate] Navigating to /home');
          context.go('/home');
        } else {
          debugPrint('[AuthGate] Navigating to /pair');
          context.go('/pair');
        }
      });
      
    } catch (e) {
      debugPrint('[AuthGate] Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _hasCouple = false; // Default to false on error
      });
      
      // Navigate to pair page on error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[AuthGate] Error occurred, navigating to /pair');
        context.go('/pair');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking couple status...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _checkCouple();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // This should not be reached due to navigation in initState
    return const SizedBox.shrink();
  }
}
