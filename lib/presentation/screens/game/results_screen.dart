import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/room_model.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common/app_button.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game    = ref.watch(gameProvider);
    final players = game.room?.sortedPlayers ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('Resultados',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary))
                .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text('+${game.myScore} puntos ganados',
                style: const TextStyle(color: AppColors.gold, fontSize: 18,
                  fontWeight: FontWeight.w600))
                .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
              ...players.asMap().entries.map((e) =>
                _PlayerResultRow(
                  rank:   e.key + 1,
                  player: e.value,
                  isMe:   e.value.userId == null, // simplificado
                ).animate(delay: (e.key * 150).ms)
                 .slideX(begin: -0.3, end: 0, duration: 400.ms)
                 .fadeIn(),
              ),
              const Spacer(),
              _PointsEarnedCard(score: game.myScore),
              const SizedBox(height: 16),
              AppButton(
                label: 'Jugar de nuevo',
                onPressed: () => context.go('/home'),
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerResultRow extends StatelessWidget {
  final int             rank;
  final RoomPlayerModel player;
  final bool            isMe;

  const _PlayerResultRow({
    required this.rank,
    required this.player,
    required this.isMe,
  });

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _rankColors = [AppColors.gold, AppColors.textSecondary,
    Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3 ? _medals[rank - 1] : '$rank';
    final color = rank <= 3 ? _rankColors[rank - 1] : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.4) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppColors.gold : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(medal,
              style: TextStyle(fontSize: rank <= 3 ? 22 : 16, color: color),
              textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceLight,
            child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(player.name,
                      style: TextStyle(
                        color: isMe ? AppColors.gold : AppColors.textPrimary,
                        fontWeight: FontWeight.w600, fontSize: 14)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const Text('(tú)',
                        style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                    if (player.isBot) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('BOT',
                          style: TextStyle(color: AppColors.textHint, fontSize: 9,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text('${player.correctAnswers} correctas',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text('${player.score}',
            style: const TextStyle(color: AppColors.gold, fontSize: 20,
              fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PointsEarnedCard extends StatelessWidget {
  final int score;
  const _PointsEarnedCard({required this.score});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withOpacity(0.5)),
    ),
    child: Column(
      children: [
        const Text('Puntos acumulados esta partida',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text('+$score pts',
          style: const TextStyle(color: AppColors.gold, fontSize: 32,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Se han sumado a tu perfil',
          style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    ),
  ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut);
}
