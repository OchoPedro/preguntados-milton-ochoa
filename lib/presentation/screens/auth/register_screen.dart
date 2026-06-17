import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import '../../widgets/common/app_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _loading       = false;
  bool _obscurePass   = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await SupabaseService.signUpWithEmail(
        email:       _emailCtrl.text.trim(),
        password:    _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
        username:    _usernameCtrl.text.trim().toLowerCase(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      String msg = 'Error al registrarse';
      if (e.toString().contains('already')) msg = 'El correo ya está registrado';
      if (e.toString().contains('username')) msg = 'El nombre de usuario no está disponible';
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Crear cuenta'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¡Únete al juego!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const Text('Crea tu cuenta y comienza a competir',
                style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
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
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textHint),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon: Icon(Icons.alternate_email, color: AppColors.textHint),
                  hintText: 'ej: jugador123',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 3) return 'Mínimo 3 caracteres';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                    return 'Solo letras, números y guión bajo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              AppButton(
                label: 'Crear cuenta',
                onPressed: _register,
                isFullWidth: true,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: RichText(
                    text: const TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(text: 'Inicia sesión',
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
