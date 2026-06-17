import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/supabase_service.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_scaffold.dart';

final _userSearchProvider = StateProvider<String>((ref) => '');

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final search     = ref.watch(_userSearchProvider);

    return AdminScaffold(
      title: 'Usuarios',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o usuario...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: () => ref.read(_userSearchProvider.notifier).state = '',
                      )
                    : null,
              ),
              onChanged: (v) => ref.read(_userSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data:    (users) {
                final filtered = search.isEmpty
                    ? users
                    : users.where((u) {
                        final name = (u['display_name'] as String? ?? '').toLowerCase();
                        final user = (u['username']     as String? ?? '').toLowerCase();
                        return name.contains(search.toLowerCase()) ||
                               user.contains(search.toLowerCase());
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin resultados',
                    style: TextStyle(color: AppColors.textHint)));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${filtered.length} usuarios',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _UserTile(
                          user: filtered[i],
                          rank: i + 1,
                          onMakeAdmin: () => _makeAdmin(context, ref, filtered[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeAdmin(BuildContext context, WidgetRef ref,
      Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Dar permisos de admin?'),
        content: Text(
          'El usuario "${user['display_name']}" podrá acceder al panel de administración.\n\n'
          'Esta acción se puede revertir eliminando su registro de la tabla admin_users.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await SupabaseService.client
        .from('admin_users')
        .upsert({'user_id': user['id']});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos de admin otorgados'),
          backgroundColor: AppColors.success));
    }
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final VoidCallback onMakeAdmin;

  const _UserTile({
    required this.user,
    required this.rank,
    required this.onMakeAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final name      = user['display_name'] as String? ?? 'Jugador';
    final username  = user['username']     as String? ?? '';
    final pts       = user['total_points'] as int;
    final wins      = user['games_won']    as int;
    final played    = user['games_played'] as int;
    final levelId   = (user['level_id']    as int?) ?? 1;
    final levelName = AppConstants.levelNames[levelId] ?? 'Aspirante';
    final created   = DateTime.parse(user['created_at'] as String).toLocal();

    final levelColors = [
      AppColors.levelAspirante, AppColors.levelSaber,
      AppColors.levelElite,     AppColors.levelLeyenda,
    ];
    final color = levelColors[(levelId - 1).clamp(0, 3)];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar con ranking
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 18)),
              ),
              Positioned(
                bottom: -1, right: -1,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text('$rank',
                    style: const TextStyle(color: AppColors.textHint,
                      fontSize: 7, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
                Text('@$username',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(levelName,
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  Text('Desde ${created.day}/${created.month}/${created.year}',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 9)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pts pts',
                style: const TextStyle(color: AppColors.gold, fontSize: 14,
                  fontWeight: FontWeight.w700)),
              Text('$wins/$played vic',
                style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onMakeAdmin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                        size: 10, color: AppColors.textHint),
                      SizedBox(width: 3),
                      Text('Admin', style: TextStyle(
                        color: AppColors.textHint, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
