import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _submitting = false;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _localError = null;
      _submitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _localError = 'E-posta ve şifre gerekli.';
        _submitting = false;
      });
      return;
    }

    bool ok;
    if (_isLogin) {
      ok = await auth.signIn(email: email, password: password);
    } else {
      if (displayName.isEmpty) {
        setState(() {
          _localError = 'İsim gerekli.';
          _submitting = false;
        });
        return;
      }
      ok = await auth.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    }

    if (!ok) {
      setState(() {
        _localError = auth.errorMessage ?? 'İşlem başarısız oldu.';
        _submitting = false;
      });
      return;
    }

    // Başarılı olursa AuthProvider durum değiştirip AuthGate otomatik olarak
    // kullanıcıyı HomeScreen'e geçirir.
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final title = _isLogin ? 'Giriş Yap' : 'Kayıt Ol';
    final buttonText = _isLogin ? 'Giriş' : 'Kayıt';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Stilya',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (!_isLogin) ...[
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'İsim',
                        hintText: 'Örn: Elif',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@mail.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),

                  if (_localError != null) ...[
                    Text(
                      _localError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: _submitting || auth.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(buttonText),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _submitting ? null : () {
                      setState(() {
                        _localError = null;
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Hesabım yok, kayıt ol'
                          : 'Hesabım var, giriş yap',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

