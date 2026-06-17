import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/challenge_model.dart';
import '../../services/supabase_service.dart';

final challengesProvider = FutureProvider<List<ChallengeModel>>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return [];

  final rows = await SupabaseService.client
      .from('challenges')
      .select('''
        *,
        user_challenges!left (
          progress,
          completed_at
        )
      ''')
      .eq('is_active', true)
      .eq('user_challenges.user_id', userId)
      .order('is_active', ascending: false);

  return (rows as List)
      .map((r) => ChallengeModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// Estadísticas rápidas de desafíos
final challengeStatsProvider = Provider.autoDispose((ref) {
  final async = ref.watch(challengesProvider);
  return async.maybeWhen(
    data: (list) => (
      total:     list.length,
      completed: list.where((c) => c.isCompleted).length,
      inProgress: list.where((c) => !c.isCompleted && c.progress > 0).length,
    ),
    orElse: () => (total: 0, completed: 0, inProgress: 0),
  );
});
