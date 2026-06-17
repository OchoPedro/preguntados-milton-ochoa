import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile_model.dart';
import '../../services/supabase_service.dart';

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return null;

  final data = await SupabaseService.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

  return ProfileModel.fromJson(data);
});

final leaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, type) async {
  final fn = type == 'weekly' ? 'get_weekly_leaderboard' : 'get_global_leaderboard';
  final rows = await SupabaseService.client.rpc(fn, params: {'p_limit': 100});
  return (rows as List).cast<Map<String, dynamic>>();
});
