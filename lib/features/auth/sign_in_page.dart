import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _signInUp() async {
    setState(() => loading = true);
    final supa = Supabase.instance.client;
    try {
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text.trim();
      final res = await supa.auth.signInWithPassword(
        email: email,
        password: pass,
      );
      if (res.session == null) {
        // nếu chưa có user -> sign up
        await supa.auth.signUp(email: email, password: pass);
      }
      if (mounted) context.go('/');
    } on AuthApiException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        // thử sign up nếu chưa tồn tại
        try {
          await Supabase.instance.client.auth.signUp(
            email: emailCtrl.text.trim(),
            password: passCtrl.text.trim(),
          );
          if (mounted) context.go('/');
        } catch (e2) {
          _showError(e2.toString());
        }
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Couple To-Do',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _signInUp,
                  child: Text(loading ? 'Loading...' : 'Sign in / Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
