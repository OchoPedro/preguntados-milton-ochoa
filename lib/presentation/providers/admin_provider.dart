import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';

// ── Verificar si el usuario actual es admin ──────────────────
final isAdminProvider = FutureProvider<bool>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return false;
  final row = await SupabaseService.client
      .from('admin_users')
      .select('user_id')
      .eq('user_id', userId)
      .maybeSingle();
  return row != null;
});

// ── Estadísticas generales ───────────────────────────────────
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final rows = await SupabaseService.client.from('admin_stats').select().single();
  return rows as Map<String, dynamic>;
});

// ── Partidas por día (últimos 7 días) ───────────────────────
final gamesPerDayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await SupabaseService.client.rpc('get_games_per_day', params: {'p_days': 7});
  return (rows as List).cast<Map<String, dynamic>>();
});

// ── Top usuarios ─────────────────────────────────────────────
final topUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await SupabaseService.client.rpc('get_top_users', params: {'p_limit': 10});
  return (rows as List).cast<Map<String, dynamic>>();
});

// ── Premios ──────────────────────────────────────────────────
final adminPrizesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await SupabaseService.client
      .from('prizes')
      .select()
      .order('points_required');
  return (rows as List).cast<Map<String, dynamic>>();
});

// ── Solicitudes de canje ─────────────────────────────────────
final adminRedemptionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, status) async {
  final base = SupabaseService.client
      .from('prize_redemptions')
      .select('*, profiles(display_name, avatar_url), prizes(name, image_url)');

  final rows = await (status != 'all' ? base.eq('status', status) : base)
      .order('requested_at', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
});

// ── Preguntas (con estadísticas) ─────────────────────────────
final adminQuestionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, filters) async {
  var query = SupabaseService.client
      .from('question_stats')
      .select();

  if (filters['difficulty'] != null) {
    query = query.eq('difficulty', filters['difficulty']);
  }
  if (filters['category'] != null) {
    query = query.eq('category', filters['category']);
  }
  if (filters['is_active'] != null) {
    query = query.eq('is_active', filters['is_active']);
  }

  final rows = await query.order('success_rate').limit(200);
  return (rows as List).cast<Map<String, dynamic>>();
});

// ── Lista de usuarios ─────────────────────────────────────────
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await SupabaseService.client
      .from('profiles')
      .select('id, display_name, username, avatar_url, total_points, level_id, games_played, games_won, created_at')
      .order('total_points', ascending: false)
      .limit(500);
  return (rows as List).cast<Map<String, dynamic>>();
});
