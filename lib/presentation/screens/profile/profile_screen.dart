import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/supabase_service.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (profile) {
          if (profile == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _AvatarSection(profile: profile),
                const SizedBox(height: 24),
                _LevelProgress(profile: profile),
                const SizedBox(height: 24),
                _StatsRow(profile: profile),
                const SizedBox(height: 24),
                _DailyPowerupsCard(userId: profile.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final dynamic profile;
  const _AvatarSection({required this.profile});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.primary,
        child: Text(
          profile.displayName?.isNotEmpty == true
              ? profile.displayName[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        ),
      ),
      const SizedBox(height: 12),
      Text(profile.displayName ?? '',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary)),
      Text('@${profile.username ?? ''}',
        style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
    ],
  );
}

class _LevelProgress extends StatelessWidget {
  final dynamic profile;
  const _LevelProgress({required this.profile});

  @override
  Widget build(BuildContext context) {
    final levelId   = profile.levelId as int;
    final levelName = AppConstants.levelNames[levelId] ?? 'Aspirante';
    final progress  = (profile.levelProgress as double).clamp(0.0, 1.0);
    final toNext    = profile.pointsToNextLevel as int;

    final levelColors = [
      AppColors.levelAspirante, AppColors.levelSaber,
      AppColors.levelElite,     AppColors.levelLeyenda,
    ];
    final color = levelColors[(levelId - 1).clamp(0, 3)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 44,
            lineWidth: 8,
            percent: levelId >= 4 ? 1.0 : progress,
            center: Text('${(progress * 100).round()}%',
              style: const TextStyle(color: AppColors.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 13)),
            progressColor: color,
            backgroundColor: AppColors.surfaceLight,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelName, style: TextStyle(color: color, fontSize: 18,
                  fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${profile.totalPoints} puntos totales',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (levelId < 4) ...[
                  const SizedBox(height: 4),
                  Text('Faltan $toNext pts para el siguiente nivel',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatCard(label: 'Partidas', value: '${profile.gamesPlayed}',
        icon: Icons.sports_esports_rounded),
      const SizedBox(width: 12),
      _StatCard(label: 'Victorias', value: '${profile.gamesWon}',
        icon: Icons.emoji_events_rounded),
      const SizedBox(width: 12),
      _StatCard(
        label: 'Win %',
        value: profile.gamesPlayed > 0
            ? '${((profile.gamesWon / profile.gamesPlayed) * 100).round()}%'
            : '0%',
        icon: Icons.percent_rounded),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 24),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AppColors.textPrimary,
            fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
        ],
      ),
    ),
  );
}

class _DailyPowerupsCard extends ConsumerWidget {
  final String userId;
  const _DailyPowerupsCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comodines diarios',
          style: TextStyle(color: AppColors.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Recibe 1 de cada comodín gratis al día',
          style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.redeem_rounded),
            label: const Text('Reclamar comodines'),
            onPressed: () async {
              final result = await SupabaseService.client.rpc(
                'claim_daily_powerups',
                params: {'p_user_id': userId},
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result == true
                    ? '¡Comodines reclamados!'
                    : 'Ya reclamaste hoy, vuelve mañana'),
                  backgroundColor: result == true ? AppColors.success : AppColors.warning,
                ));
              }
            },
          ),
        ),
      ],
    ),
  );
}
