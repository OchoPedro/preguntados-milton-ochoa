import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import '../../providers/profile_provider.dart';

final prizesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await SupabaseService.client
      .from('prizes')
      .select()
      .eq('is_active', true)
      .order('points_required');
  return (rows as List).cast<Map<String, dynamic>>();
});

class PrizesScreen extends ConsumerWidget {
  const PrizesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prizesAsync  = ref.watch(prizesProvider);
    final profileAsync = ref.watch(profileProvider);
    final myPoints     = profileAsync.value?.totalPoints ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tienda de Premios')),
      body: Column(
        children: [
          _PointsBanner(points: myPoints),
          Expanded(
            child: prizesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data:    (prizes) => prizes.isEmpty
                ? const Center(
                    child: Text('Sin premios disponibles',
                      style: TextStyle(color: AppColors.textHint)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12,
                      mainAxisSpacing: 12, childAspectRatio: 0.75,
                    ),
                    itemCount: prizes.length,
                    itemBuilder: (_, i) => _PrizeCard(
                      prize: prizes[i],
                      myPoints: myPoints,
                      onRedeem: () => _confirmRedeem(context, ref, prizes[i]),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRedeem(BuildContext context, WidgetRef ref, Map<String, dynamic> prize) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Canjear premio?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prize['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Se descontarán ${prize['points_required']} puntos de tu cuenta.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _redeem(context, ref, prize['id'] as String);
            },
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, String prizeId) async {
    final userId = SupabaseService.currentUserId!;
    final result = await SupabaseService.client
        .rpc('redeem_prize', params: {'p_user_id': userId, 'p_prize_id': prizeId});

    final success = result['success'] as bool;
    final msg     = success
        ? '¡Premio canjeado! El administrador te contactará pronto.'
        : result['error'] as String? ?? 'Error al canjear';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg),
          backgroundColor: success ? AppColors.success : AppColors.error));
      if (success) ref.invalidate(profileProvider);
    }
  }
}

class _PointsBanner extends StatelessWidget {
  final int points;
  const _PointsBanner({required this.points});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    color: AppColors.primaryDark,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: AppColors.gold, size: 20),
        const SizedBox(width: 8),
        Text('Tus puntos disponibles: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text('$points pts',
          style: const TextStyle(color: AppColors.gold, fontSize: 16,
            fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _PrizeCard extends StatelessWidget {
  final Map<String, dynamic> prize;
  final int myPoints;
  final VoidCallback onRedeem;
  const _PrizeCard({required this.prize, required this.myPoints, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final name     = prize['name'] as String;
    final desc     = prize['description'] as String? ?? '';
    final required = prize['points_required'] as int;
    final stock    = prize['stock'] as int;
    final canAfford = myPoints >= required && stock > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? AppColors.gold.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.card_giftcard_rounded,
                  size: 48, color: canAfford ? AppColors.gold : AppColors.textHint),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                if (desc.isNotEmpty)
                  Text(desc,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$required pts',
                      style: TextStyle(
                        color: canAfford ? AppColors.gold : AppColors.textHint,
                        fontSize: 12, fontWeight: FontWeight.w700)),
                    Text('Stock: $stock',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? onRedeem : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(canAfford ? 'Canjear' : 'Sin puntos'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
