import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/room_model.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/game/player_seat_widget.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final room = game.room;

    if (room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sala de espera'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _RoomCodeCard(code: room.code),
              const SizedBox(height: 24),
              _PlayersGrid(players: room.players, maxPlayers: room.maxPlayers),
              const SizedBox(height: 24),
              _WaitingIndicator(room: room),
              const Spacer(),
              if (game.phase == GamePhase.lobby)
                AppButton(
                  label: 'Jugar',
                  onPressed: room.canStart ? () => _startGame(ref) : null,
                  isFullWidth: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(WidgetRef ref) {
    // El host inicia → la Edge Function start-game maneja el resto
    // La sala cambia a 'in_progress' vía Realtime
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Salir de la sala?'),
        content: const Text('Perderás tu lugar en esta partida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); context.go('/home'); },
            child: const Text('Salir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  final String code;
  const _RoomCodeCard({required this.code});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold, width: 1.5),
    ),
    child: Column(
      children: [
        const Text('Código de sala',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(code,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.copy, color: AppColors.gold),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              },
            ),
          ],
        ),
        const Text('Comparte este código con tus amigos',
          style: TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    ),
  );
}

class _PlayersGrid extends StatelessWidget {
  final List<RoomPlayerModel> players;
  final int maxPlayers;
  const _PlayersGrid({required this.players, required this.maxPlayers});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
    ),
    itemCount: maxPlayers,
    itemBuilder: (_, i) {
      final player = i < players.length ? players[i] : null;
      return PlayerSeatWidget(player: player, seatNumber: i + 1);
    },
  );
}

class _WaitingIndicator extends StatelessWidget {
  final RoomModel room;
  const _WaitingIndicator({required this.room});

  @override
  Widget build(BuildContext context) {
    final waiting = room.waitingUntil;
    if (waiting == null) return const SizedBox.shrink();

    final remaining = waiting.difference(DateTime.now());
    final secs = remaining.inSeconds.clamp(0, 999);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        const SizedBox(width: 8),
        Text(
          'Esperando jugadores... ${secs}s',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
