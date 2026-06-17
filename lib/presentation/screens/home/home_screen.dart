import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common/app_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text(e.toString())),
          data:    (profile) => _HomeContent(
            profile: profile,
            isAdmin: isAdminAsync.value ?? false,
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final dynamic profile;
  final bool    isAdmin;
  const _HomeContent({required this.profile, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(profile: profile),
          const SizedBox(height: 24),
          _LevelCard(profile: profile),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Jugar ahora'),
          const SizedBox(height: 12),
          _PlayButtons(isLoading: game.phase != GamePhase.idle),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Acceso rápido'),
          const SizedBox(height: 12),
          _QuickActions(isAdmin: isAdmin),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final dynamic profile;
  const _TopBar({required this.profile});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${profile?.displayName?.split(' ').first ?? 'Jugador'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            Text('${profile?.totalPoints ?? 0} puntos totales',
              style: const TextStyle(color: AppColors.gold, fontSize: 13)),
          ],
        ),
      ),
      GestureDetector(
        onTap: () => context.push('/profile'),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(
            profile?.displayName?.isNotEmpty == true
                ? profile!.displayName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ),
      ),
    ],
  );
}

class _LevelCard extends StatelessWidget {
  final dynamic profile;
  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final levelId    = profile?.levelId ?? 1;
    final levelName  = AppConstants.levelNames[levelId] ?? 'Aspirante';
    final progress   = profile?.levelProgress ?? 0.0;
    final ptsToNext  = profile?.pointsToNextLevel ?? 0;

    final colors = [
      AppColors.levelAspirante, AppColors.levelSaber,
      AppColors.levelElite, AppColors.levelLeyenda,
    ];
    final color = colors[(levelId - 1).clamp(0, 3)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, color.withOpacity(0.6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(levelName,
                style: TextStyle(color: color, fontSize: 20,
                  fontWeight: FontWeight.w700)),
              Icon(Icons.emoji_events_rounded, color: color, size: 28),
            ],
          ),
          if (levelId < 4) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progreso al siguiente nivel',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Text('$ptsToNext pts restantes',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('¡Leyenda máxima alcanzada!',
                style: TextStyle(color: AppColors.gold, fontSize: 13,
                  fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _PlayButtons extends ConsumerWidget {
  final bool isLoading;
  const _PlayButtons({required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      AppButton(
        label: 'Jugar en línea',
        icon: Icons.public,
        onPressed: isLoading ? null : () async {
          await ref.read(gameProvider.notifier).findPublicRoom();
          if (context.mounted) context.push('/lobby');
        },
        isFullWidth: true,
        isLoading: isLoading,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Crear sala',
              icon: Icons.add,
              isOutlined: true,
              onPressed: isLoading ? null : () async {
                await ref.read(gameProvider.notifier).createRoom(isPrivate: true);
                if (context.mounted) context.push('/lobby');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Unirme',
              icon: Icons.login,
              isOutlined: true,
              onPressed: () => _showJoinDialog(context, ref),
            ),
          ),
        ],
      ),
    ],
  );

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unirse a sala'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 6,
            fontWeight: FontWeight.w700, fontSize: 20),
          decoration: const InputDecoration(hintText: 'Código de sala'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(gameProvider.notifier).joinByCode(ctrl.text);
              if (context.mounted) context.push('/lobby');
            },
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isAdmin;
  const _QuickActions({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction(icon: Icons.leaderboard_rounded,   label: 'Ranking',
        onTap: () => context.push('/leaderboard')),
      _QuickAction(icon: Icons.card_giftcard_rounded, label: 'Premios',
        onTap: () => context.push('/prizes')),
      _QuickAction(icon: Icons.military_tech_rounded, label: 'Desafíos',
        onTap: () => context.push('/challenges')),
      _QuickAction(icon: Icons.person_outline_rounded, label: 'Perfil',
        onTap: () => context.push('/profile')),
      if (isAdmin)
        _QuickAction(icon: Icons.admin_panel_settings_rounded, label: 'Admin',
          color: AppColors.gold,
          onTap: () => context.push('/admin')),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isAdmin ? 5 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: items,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final Color?    color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
    required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color ?? AppColors.gold, size: 32),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary,
            fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary));
}
