import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';

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
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Icon(Icons.quiz_rounded, size: 60, color: AppColors.gold),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text('Preguntados',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary))
            .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3, end: 0),
          const Text('Milton Ochoa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
              color: AppColors.gold, letterSpacing: 3))
            .animate(delay: 500.ms).fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 48),
          const SizedBox(width: 32, height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.gold))
            .animate(delay: 800.ms).fadeIn(),
        ],
      ),
    ),
  );
}
