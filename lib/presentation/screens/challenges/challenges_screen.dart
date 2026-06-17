import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../providers/challenges_provider.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);
    final stats           = ref.watch(challengeStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Desafíos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(challengesProvider),
          ),
        ],
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorState(message: e.toString(),
          onRetry: () => ref.invalidate(challengesProvider)),
        data: (challenges) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _StatsHeader(stats: stats)),
            SliverToBoxAdapter(
              child: _PowerupInfo(),
            ),
            if (challenges.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Sin desafíos disponibles',
                  style: TextStyle(color: AppColors.textHint))),
              )
            else ...[
              _SectionHeader(
                label: 'En progreso',
                count: stats.inProgress,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final list = challenges
                          .where((c) => !c.isCompleted && c.progress > 0)
                          .toList();
                      if (i >= list.length) return null;
                      return _ChallengeCard(challenge: list[i], index: i);
                    },
                    childCount: stats.inProgress,
                  ),
                ),
              ),
              _SectionHeader(
                label: 'Disponibles',
                count: stats.total - stats.completed - stats.inProgress,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final list = challenges
                          .where((c) => !c.isCompleted && c.progress == 0)
                          .toList();
                      if (i >= list.length) return null;
                      return _ChallengeCard(challenge: list[i], index: i);
                    },
                    childCount: challenges
                        .where((c) => !c.isCompleted && c.progress == 0)
                        .length,
                  ),
                ),
              ),
              _SectionHeader(
                label: 'Completados',
                count: stats.completed,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final list = challenges
                          .where((c) => c.isCompleted)
                          .toList();
                      if (i >= list.length) return null;
                      return _ChallengeCard(challenge: list[i], index: i);
                    },
                    childCount: stats.completed,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Header con estadísticas ───────────────────────────────────────────────
class _StatsHeader extends StatelessWidget {
  final ({int total, int completed, int inProgress}) stats;
  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatBubble(
              label: 'Total',
              value: '${stats.total}',
              icon: Icons.emoji_events_outlined,
              color: AppColors.textSecondary,
            ),
            _StatBubble(
              label: 'En progreso',
              value: '${stats.inProgress}',
              icon: Icons.hourglass_bottom_rounded,
              color: AppColors.warning,
            ),
            _StatBubble(
              label: 'Completados',
              value: '${stats.completed}',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
          ],
        ),
        if (stats.total > 0) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progreso general',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(
                '${((stats.completed / stats.total) * 100).round()}%',
                style: const TextStyle(color: AppColors.gold,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: stats.total > 0
                ? (stats.completed / stats.total).clamp(0.0, 1.0)
                : 0.0,
            backgroundColor: AppColors.surfaceLight,
            progressColor: AppColors.gold,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
        ],
      ],
    ),
  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
}

class _StatBubble extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _StatBubble({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 6),
      Text(value,
        style: TextStyle(color: color, fontSize: 20,
          fontWeight: FontWeight.w700)),
      Text(label,
        style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
    ],
  );
}

// ─── Info de comodines ─────────────────────────────────────────────────────
class _PowerupInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Al completar un desafío recibes comodines como recompensa. '
            'Úsalos durante las partidas.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

// ─── Encabezado de sección ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final int    count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Text(label,
              style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                style: const TextStyle(color: AppColors.textSecondary,
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de desafío ───────────────────────────────────────────────────────
class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final int            index;
  const _ChallengeCard({required this.challenge, required this.index});

  static const _powerupIcons = {
    PowerupType.fiftyFifty: Icons.filter_2,
    PowerupType.extraTime:  Icons.timer_outlined,
    PowerupType.skip:       Icons.skip_next_rounded,
  };
  static const _powerupColors = {
    PowerupType.fiftyFifty: AppColors.info,
    PowerupType.extraTime:  AppColors.success,
    PowerupType.skip:       AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final isCompleted  = challenge.isCompleted;
    final inProgress   = !isCompleted && challenge.progress > 0;
    final pct          = challenge.progressPercent;
    final rewardIcon   = _powerupIcons[challenge.rewardType]!;
    final rewardColor  = _powerupColors[challenge.rewardType]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withOpacity(0.07)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.4)
              : inProgress
                  ? AppColors.gold.withOpacity(0.3)
                  : AppColors.border,
          width: isCompleted || inProgress ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono de estado
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.success, size: 24)
                      : Icon(Icons.emoji_events_outlined,
                          color: inProgress ? AppColors.gold : AppColors.textHint,
                          size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(challenge.title,
                              style: TextStyle(
                                color: isCompleted
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: isCompleted
                                    ? TextDecoration.none : null,
                              )),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('¡Listo!',
                                style: TextStyle(color: AppColors.success,
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(challenge.requirementLabel,
                        style: const TextStyle(color: AppColors.textSecondary,
                          fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),

            // Barra de progreso
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${challenge.progress} / ${challenge.targetValue}',
                    style: TextStyle(
                      color: inProgress ? AppColors.gold : AppColors.textHint,
                      fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text('${(pct * 100).round()}%',
                    style: TextStyle(
                      color: inProgress ? AppColors.gold : AppColors.textHint,
                      fontSize: 11)),
                ],
              ),
              const SizedBox(height: 5),
              LinearPercentIndicator(
                lineHeight: 7,
                percent: pct,
                backgroundColor: AppColors.surfaceLight,
                progressColor: inProgress ? AppColors.gold : AppColors.border,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
                animation: true,
                animationDuration: 600,
              ),
            ],

            // Recompensa
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.redeem_rounded,
                  color: AppColors.textHint, size: 13),
                const SizedBox(width: 4),
                const Text('Recompensa: ',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: rewardColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rewardColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rewardIcon, color: rewardColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'x${challenge.rewardQty} ${challenge.rewardLabel}',
                        style: TextStyle(color: rewardColor,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isCompleted && challenge.completedAt != null) ...[
                  const Spacer(),
                  Text(
                    _formatDate(challenge.completedAt!),
                    style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                ],
              ],
            ),
          ],
        ),
      ),
    )
    .animate(delay: (index * 50).ms)
    .fadeIn(duration: 350.ms)
    .slideY(begin: 0.15, end: 0, duration: 350.ms);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}

// ─── Estado de error ───────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
