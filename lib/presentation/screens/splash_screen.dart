import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';
import '../widgets/common/mo_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    context.go(SupabaseService.isAuthenticated ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primaryDark,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MoLogo(size: 140, showTagline: false)
            .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 28),
          const Text('Preguntados',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: 1))
            .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3, end: 0),
          const Text('Milton Ochoa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
              color: AppColors.accent, letterSpacing: 3))
            .animate(delay: 500.ms).fadeIn().slideY(begin: 0.3, end: 0),
          const Text('Expertos en Evaluación',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400,
              color: AppColors.textSecondary, letterSpacing: 2))
            .animate(delay: 650.ms).fadeIn(),
          const SizedBox(height: 48),
          const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent))
            .animate(delay: 800.ms).fadeIn(),
        ],
      ),
    ),
  );
}
