import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import '../../widgets/common/app_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _loading     = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await SupabaseService.signInWithEmail(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Correo o contraseña incorrectos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService.signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Error al iniciar con Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: const Icon(Icons.quiz_rounded,
                        size: 40, color: AppColors.gold),
                    ),
                    const SizedBox(height: 16),
                    const Text('¡Bienvenido!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                    const Text('Inicia sesión para jugar',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: Text(_error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                ),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Ingresa un correo válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textHint),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) => v == null || v.length < 6
                    ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Iniciar sesión',
                onPressed: _login,
                isFullWidth: true,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Divider(color: AppColors.border)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(color: AppColors.textHint))),
                const Expanded(child: Divider(color: AppColors.border)),
              ]),
              const SizedBox(height: 16),
              AppButton(
                label: 'Continuar con Google',
                onPressed: _loginWithGoogle,
                isFullWidth: true,
                isOutlined: true,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/register'),
                  child: RichText(
                    text: const TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(text: 'Regístrate',
                          style: TextStyle(color: AppColors.gold,
                            fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
