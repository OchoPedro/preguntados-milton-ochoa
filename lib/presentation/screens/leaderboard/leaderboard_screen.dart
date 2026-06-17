import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/profile_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Tabla de líderes'),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: AppColors.gold,
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(text: 'Global'),
          Tab(text: 'Semanal'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: const [
        _LeaderboardTab(type: 'global'),
        _LeaderboardTab(type: 'weekly'),
      ],
    ),
  );
}

class _LeaderboardTab extends ConsumerWidget {
  final String type;
  const _LeaderboardTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider(type));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data:    (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Text('Sin datos aún', style: TextStyle(color: AppColors.textHint)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (_, i) => _LeaderboardRow(row: rows[i], index: i),
        );
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final int index;
  const _LeaderboardRow({required this.row, required this.index});

  static const _medals  = ['🥇', '🥈', '🥉'];
  static const _bgColors = [
    Color(0xFF2A1F00), Color(0xFF1A1A1A), Color(0xFF1A1200),
  ];

  @override
  Widget build(BuildContext context) {
    final rank      = (row['rank'] as num).toInt();
    final name      = row['display_name'] as String? ?? 'Jugador';
    final points    = (row['total_points'] ?? row['weekly_points'] ?? 0) as int;
    final levelId   = (row['level_id'] as int?) ?? 1;
    final levelName = AppConstants.levelNames[levelId] ?? 'Aspirante';

    final isTop3 = rank <= 3;
    final bg     = isTop3 ? _bgColors[rank - 1] : AppColors.surface;
    final medal  = isTop3 ? _medals[rank - 1] : '$rank';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3 ? AppColors.gold.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(medal,
              style: TextStyle(fontSize: isTop3 ? 22 : 15,
                color: isTop3 ? AppColors.gold : AppColors.textHint),
              textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
                Text(levelName, style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text('$points pts',
            style: const TextStyle(color: AppColors.gold, fontSize: 15,
              fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
