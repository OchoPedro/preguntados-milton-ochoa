import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/room_model.dart';

class PlayerSeatWidget extends StatelessWidget {
  final RoomPlayerModel? player;
  final int seatNumber;

  const PlayerSeatWidget({super.key, this.player, required this.seatNumber});

  @override
  Widget build(BuildContext context) {
    if (player == null) return _EmptySeat(seatNumber: seatNumber);
    return _FilledSeat(player: player!);
  }
}

class _EmptySeat extends StatelessWidget {
  final int seatNumber;
  const _EmptySeat({required this.seatNumber});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceLight.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border.withOpacity(0.5),
        style: BorderStyle.solid, width: 1.5),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_add_outlined,
          color: AppColors.textHint, size: 28),
        const SizedBox(height: 6),
        const Text('Esperando...',
          style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    ),
  );
}

class _FilledSeat extends StatelessWidget {
  final RoomPlayerModel player;
  const _FilledSeat({required this.player});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.all(10),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 6),
        Text(player.name,
          style: const TextStyle(color: AppColors.textPrimary,
            fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        if (player.isBot)
          const Text('BOT',
            style: TextStyle(color: AppColors.textHint, fontSize: 9,
              fontWeight: FontWeight.w700)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Listo',
            style: TextStyle(color: Colors.green, fontSize: 9,
              fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
