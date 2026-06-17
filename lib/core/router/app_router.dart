import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/game/lobby_screen.dart';
import '../../presentation/screens/game/game_screen.dart';
import '../../presentation/screens/game/results_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/leaderboard/leaderboard_screen.dart';
import '../../presentation/screens/prizes/prizes_screen.dart';
import '../../presentation/screens/challenges/challenges_screen.dart';
import '../../presentation/screens/admin/admin_dashboard.dart';
import '../../presentation/screens/admin/admin_prizes_screen.dart';
import '../../presentation/screens/admin/admin_redemptions_screen.dart';
import '../../presentation/screens/admin/admin_questions_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/providers/admin_provider.dart';
import '../../services/supabase_service.dart';
import '../constants/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isAuth      = SupabaseService.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                          state.matchedLocation.startsWith('/register') ||
                          state.matchedLocation == '/splash';

      // Sin sesión → ir a login
      if (!isAuth && !isAuthRoute) return '/login';

      // Ya autenticado → no mostrar login/register
      if (isAuth && (state.matchedLocation == '/login' ||
                     state.matchedLocation == '/register')) return '/home';

      // Rutas de admin → verificar rol
      if (state.matchedLocation.startsWith('/admin')) {
        final isAdmin = await ref.read(isAdminProvider.future);
        if (!isAdmin) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/lobby',    builder: (_, __) => const LobbyScreen()),
      GoRoute(path: '/game',     builder: (_, __) => const GameScreen()),
      GoRoute(path: '/results',  builder: (_, __) => const ResultsScreen()),
      GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/prizes',      builder: (_, __) => const PrizesScreen()),
      GoRoute(path: '/challenges',  builder: (_, __) => const ChallengesScreen()),

      // ── Panel de administración ──────────────────────────────────────────
      GoRoute(path: '/admin',              builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/admin/prizes',       builder: (_, __) => const AdminPrizesScreen()),
      GoRoute(path: '/admin/redemptions',  builder: (_, __) => const AdminRedemptionsScreen()),
      GoRoute(path: '/admin/questions',    builder: (_, __) => const AdminQuestionsScreen()),
      GoRoute(path: '/admin/users',        builder: (_, __) => const AdminUsersScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Página no encontrada',
              style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

