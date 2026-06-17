import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/room_model.dart';

class PlayersScoreboard extends StatelessWidget {
  final List<RoomPlayerModel> players;
  const PlayersScoreboard({super.key, required this.players});

  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    color: AppColors.primaryDark,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: players.map((p) => _PlayerChip(player: p)).toList(),
    ),
  );
}

class _PlayerChip extends StatelessWidget {
  final RoomPlayerModel player;
  const _PlayerChip({required this.player});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Stack(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            ),
          ),
          if (player.streak >= 3)
            Positioned(
              right: -2, top: -2,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryDark, width: 1),
                ),
                child: const Icon(Icons.local_fire_department,
                  size: 8, color: Colors.white),
              ),
            ),
        ],
      ),
      const SizedBox(height: 2),
      Text('${player.score}',
        style: const TextStyle(color: AppColors.gold, fontSize: 11,
          fontWeight: FontWeight.w700)),
    ],
  );
}
