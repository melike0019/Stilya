import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();

  bool _submitting       = false;
  bool _obscurePassword  = true;
  String? _localError;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animCtrl.reset();
    setState(() {
      _isLogin = !_isLogin;
      _localError = null;
    });
    _animCtrl.forward();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _localError = null;
      _submitting = true;
    });

    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final name     = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _localError = 'E-posta ve şifre gereklidir.';
        _submitting = false;
      });
      return;
    }

    bool ok;
    if (_isLogin) {
      ok = await auth.signIn(email: email, password: password);
    } else {
      if (name.isEmpty) {
        setState(() {
          _localError = 'İsim gereklidir.';
          _submitting = false;
        });
        return;
      }
      ok = await auth.signUp(email: email, password: password, displayName: name);
    }

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _localError = auth.errorMessage ?? 'İşlem başarısız oldu.';
        _submitting = false;
      });
      return;
    }

    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8A3A56),
              Color(0xFFB05070),
              Color(0xFFE8A0BB),
              Color(0xFFFCE8F3),
            ],
            stops: [0.0, 0.25, 0.6, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
              child: Column(
                children: [
                  // ─── Header ─────────────────────────────────────
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 36),

                  // ─── Form Card ──────────────────────────────────
                  _buildFormCard(auth),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
            border: Border.all(color: Colors.white.withAlpha(150), width: 1.5),
          ),
          child: Center(
            child: Text(
              'S',
              style: GoogleFonts.playfairDisplay(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'STILYA',
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Stilin, Sana Özgü',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: Colors.white.withAlpha(200),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A3A56).withAlpha(40),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Tab switcher ──────────────────────────────────
              _buildTabSwitcher(),
              const SizedBox(height: 24),

              // ─── Fields ────────────────────────────────────────
              if (!_isLogin) ...[
                _buildField(
                  controller: _nameController,
                  label: 'İsim',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
              ],
              _buildField(
                controller: _emailController,
                label: 'E-posta',
                icon: Icons.mail_outline,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildPasswordField(),

              // ─── Error ─────────────────────────────────────────
              if (_localError != null) ...[
                const SizedBox(height: 14),
                _buildErrorBanner(_localError!),
              ],

              const SizedBox(height: 22),

              // ─── Submit Button ─────────────────────────────────
              _buildSubmitButton(auth),

              // ─── Forgot Password (login only) ──────────────────
              if (_isLogin) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _submitting ? null : _showForgotPassword,
                    child: Text(
                      'Şifremi Unuttum',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 8),

              // ─── Switch mode ───────────────────────────────────
              const Divider(height: 1),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _submitting ? null : _toggleMode,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textMedium),
                      children: [
                        TextSpan(
                          text: _isLogin
                              ? 'Hesabın yok mu? '
                              : 'Zaten üye misin? ',
                        ),
                        TextSpan(
                          text: _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryRose,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.bgEnd,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabOption(
            label: 'Giriş Yap',
            selected: _isLogin,
            onTap: _isLogin ? null : _toggleMode,
          ),
          _TabOption(
            label: 'Kayıt Ol',
            selected: !_isLogin,
            onTap: !_isLogin ? null : _toggleMode,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: 'Şifre',
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: AppTheme.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthProvider auth) {
    final loading = _submitting || auth.isLoading;
    return GestureDetector(
      onTap: loading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [AppTheme.darkRose, AppTheme.primaryRose],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: loading ? AppTheme.lightRose : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryRose.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryRose),
                )
              : Text(
                  _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Şifre Sıfırla',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'E-posta adresinize sıfırlama bağlantısı göndereceğiz.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.mail_outline, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await context.read<AuthProvider>().resetPassword(email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Sıfırlama bağlantısı gönderildi.'
                          : 'Bir hata oluştu.'),
                    ),
                  );
                },
                child: const Text('Gönder'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab Option Widget ─────────────────────────────────────────────────────
class _TabOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _TabOption({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryRose.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primaryRose : AppTheme.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
