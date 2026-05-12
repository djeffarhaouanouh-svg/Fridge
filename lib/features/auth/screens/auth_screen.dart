import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/providers/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Remplis tous les champs.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = _isLogin
        ? await AuthService.login(email, password)
        : await AuthService.register(_nameCtrl.text.trim(), email, password);

    if (!mounted) return;
    if (result.success) {
      ref.read(authStateProvider.notifier).state = true;
    } else {
      setState(() { _error = result.error; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.paper,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Logo
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppTokens.coralSoft,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: const Icon(Icons.kitchen, color: AppTokens.coral, size: 22),
                ),
                const SizedBox(width: 10),
                Text('fridge·ai', style: GoogleFonts.fraunces(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppTokens.coral,
                )),
              ]),

              const SizedBox(height: 32),

              Text(_isLogin ? 'Bon retour 👋' : 'Créer un compte',
                style: GoogleFonts.fraunces(
                  fontSize: 26, fontWeight: FontWeight.w700, color: AppTokens.ink,
                )),
              const SizedBox(height: 6),
              Text(
                _isLogin
                  ? 'Connecte-toi pour retrouver tes recettes'
                  : 'Rejoins fridge·ai gratuitement',
                style: GoogleFonts.inter(fontSize: 13.5, color: AppTokens.muted),
              ),

              const SizedBox(height: 28),

              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  _Tab(
                    label: 'Connexion', active: _isLogin,
                    onTap: () => setState(() { _isLogin = true; _error = null; }),
                  ),
                  _Tab(
                    label: 'Inscription', active: !_isLogin,
                    onTap: () => setState(() { _isLogin = false; _error = null; }),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              if (!_isLogin) ...[
                _Field(ctrl: _nameCtrl, label: 'PRÉNOM', hint: 'Thomas'),
                const SizedBox(height: 16),
              ],
              _Field(
                ctrl: _emailCtrl, label: 'EMAIL', hint: 'ton@email.fr',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _Field(
                ctrl: _passwordCtrl, label: 'MOT DE PASSE',
                hint: '••••••••', obscure: true,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(_error!,
                    style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFD32F2F),
                    )),
                ),
              ],

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _loading ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _loading ? AppTokens.coralSoft : AppTokens.coral,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Center(
                    child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: AppTokens.coral, strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Se connecter' : 'Créer mon compte',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.inter(
            fontSize: 13.5, fontWeight: FontWeight.w600,
            color: active ? AppTokens.ink : AppTokens.muted,
          )),
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool obscure;
  final TextInputType keyboard;
  const _Field({
    required this.ctrl, required this.label, required this.hint,
    this.obscure = false, this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 10.5, fontWeight: FontWeight.w700,
        color: AppTokens.muted, letterSpacing: 0.8,
      )),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: GoogleFonts.inter(fontSize: 14.5, color: AppTokens.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 14.5, color: AppTokens.placeholder),
          filled: true,
          fillColor: AppTokens.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            borderSide: const BorderSide(color: AppTokens.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            borderSide: const BorderSide(color: AppTokens.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            borderSide: const BorderSide(color: AppTokens.coral, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    ],
  );
}
