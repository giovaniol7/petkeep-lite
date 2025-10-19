import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha e-mail e senha.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.authenticateAccount(
        context: context,
        email: _email.text.trim(),
        password: _password.text.trim(),
        saveLogin: true,
        routeAfterLogin: '/onboarding',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login PetKeeper')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: const Text('Entrar')),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider(height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("ou", style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                ),
                const Expanded(child: Divider(height: 1)),
              ],
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: () {
                      setState(() => _loading = true);
                      try {
                        AuthService.signInWithGoogle(context);
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                    icon: Icon(Icons.g_mobiledata, size: 30),
                    label: const Text('Entrar com Google', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
