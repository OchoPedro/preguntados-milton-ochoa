import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_scaffold.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync    = ref.watch(adminStatsProvider);
    final topAsync      = ref.watch(topUsersProvider);
    final gamesAsync    = ref.watch(gamesPerDayProvider);

    return AdminScaffold(
      title: 'Dashboard',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(topUsersProvider);
          ref.invalidate(gamesPerDayProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Resumen general'),
              const SizedBox(height: 12),
              statsAsync.when(
                loading: () => const _StatsShimmer(),
                error:   (e, _) => _ErrorCard(message: e.toString()),
                data:    (stats) => _StatsGrid(stats: stats),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Partidas últimos 7 días'),
              const SizedBox(height: 12),
              gamesAsync.when(
                loading: () => const SizedBox(height: 120,
                  child: Center(child: CircularProgressIndicator())),
                error:   (e, _) => _ErrorCard(message: e.toString()),
                data:    (rows) => _GamesBarChart(rows: rows),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Top 10 jugadores'),
              const SizedBox(height: 12),
              topAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:   (e, _) => _ErrorCard(message: e.toString()),
                data:    (users) => _TopUsersList(users: users),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats grid ────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Total usuarios',    '${stats['total_users'] ?? 0}',      Icons.people_rounded,         AppColors.info),
      _StatItem('Nuevos esta semana','${stats['new_users_week'] ?? 0}',    Icons.person_add_rounded,     AppColors.success),
      _StatItem('Partidas totales',  '${stats['total_games'] ?? 0}',      Icons.sports_esports_rounded, AppColors.gold),
      _StatItem('En juego ahora',    '${stats['active_games'] ?? 0}',     Icons.bolt_rounded,           AppColors.warning),
      _StatItem('Preguntas caché',   '${stats['total_questions'] ?? 0}',  Icons.quiz_rounded,           AppColors.levelSaber),
      _StatItem('Canjes pendientes', '${stats['pending_redemptions'] ?? 0}', Icons.pending_actions_rounded,
        (stats['pending_redemptions'] ?? 0) > 0 ? AppColors.error : AppColors.textHint),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _StatCard(item: items[i])
          .animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.2, end: 0),
    );
  }
}

class _StatItem {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: item.color.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: item.color, size: 24),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.value,
              style: TextStyle(color: item.color, fontSize: 26,
                fontWeight: FontWeight.w700)),
            Text(item.label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ],
    ),
  );
}

// ─── Bar chart de partidas ─────────────────────────────────────────────────
class _GamesBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _GamesBarChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Sin partidas esta semana',
          style: TextStyle(color: AppColors.textHint)),
      );
    }

    final maxVal = rows
        .map((r) => (r['games'] as num).toInt())
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rows.map((r) {
          final games = (r['games'] as num).toInt();
          final day   = (r['day'] as String).substring(5); // MM-DD
          final pct   = maxVal > 0 ? games / maxVal : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$games',
                    style: const TextStyle(color: AppColors.gold,
                      fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: 600.ms,
                    height: (80 * pct).clamp(4.0, 80.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gold, AppColors.goldDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(day,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Top usuarios ──────────────────────────────────────────────────────────
class _TopUsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const _TopUsersList({required this.users});

  @override
  Widget build(BuildContext context) => Column(
    children: users.asMap().entries.map((e) {
      final u        = e.value;
      final rank     = e.key + 1;
      final levelId  = (u['level_id'] as int?) ?? 1;
      final color    = [
        AppColors.levelAspirante, AppColors.levelSaber,
        AppColors.levelElite,     AppColors.levelLeyenda,
      ][(levelId - 1).clamp(0, 3)];

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('$rank',
                style: TextStyle(
                  color: rank <= 3 ? AppColors.gold : AppColors.textHint,
                  fontWeight: FontWeight.w700, fontSize: rank <= 3 ? 16 : 13),
                textAlign: TextAlign.center),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                (u['display_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['display_name'] as String? ?? 'Jugador',
                    style: const TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(u['level_name'] as String? ?? '',
                    style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${u['total_points'] ?? 0} pts',
                  style: const TextStyle(color: AppColors.gold,
                    fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${u['games_won'] ?? 0} victorias',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ],
        ),
      ).animate(delay: (e.key * 40).ms).fadeIn().slideX(begin: 0.1, end: 0);
    }).toList(),
  );
}

// ─── Helpers ───────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.textPrimary,
      fontSize: 15, fontWeight: FontWeight.w600));
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.6,
    children: List.generate(6, (_) => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(duration: 1200.ms, color: AppColors.surfaceLight)),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
          style: const TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    ),
  );
}
