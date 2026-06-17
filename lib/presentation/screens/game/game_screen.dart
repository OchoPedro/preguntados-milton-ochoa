import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/room_model.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game/question_card.dart';
import '../../widgets/game/timer_bar.dart';
import '../../widgets/game/players_scoreboard.dart';
import '../../widgets/game/powerup_bar.dart';
import 'results_screen.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);

    // Navegar a resultados cuando termina
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.phase == GamePhase.gameOver && prev?.phase != GamePhase.gameOver) {
        context.pushReplacement('/results');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (game.phase) {
          GamePhase.countdown   => _CountdownOverlay(game: game),
          GamePhase.question    => _QuestionView(game: game),
          GamePhase.showResults => _RoundResultView(game: game),
          _                     => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

// ─── Cuenta regresiva al inicio ───────────────────────────────────────────
class _CountdownOverlay extends StatelessWidget {
  final GameState game;
  const _CountdownOverlay({required this.game});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¡Prepárate!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        Text('${game.secondsLeft}',
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w700,
            color: AppColors.gold))
          .animate(onPlay: (c) => c.repeat())
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1),
            duration: 800.ms, curve: Curves.easeOut),
      ],
    ),
  );
}

// ─── Vista de pregunta ────────────────────────────────────────────────────
class _QuestionView extends ConsumerWidget {
  final GameState game;
  const _QuestionView({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final round    = game.currentRound;
    final question = round?.question;

    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _TopBar(game: game),
        TimerBar(secondsLeft: game.secondsLeft,
          total: AppConstants.secondsPerQuestion),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: QuestionCard(
                    question:     question,
                    roundNumber:  round!.roundNumber,
                    totalRounds:  game.totalRounds,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 4,
                  child: _AnswerOptions(game: game, ref: ref),
                ),
                const SizedBox(height: 8),
                PowerupBar(roomPlayerId: '', hasAnswered: game.hasAnswered),
              ],
            ),
          ),
        ),
        PlayersScoreboard(players: game.room?.sortedPlayers ?? []),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameState game;
  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Pregunta ${game.roundNumber}/${game.totalRounds}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.gold, size: 18),
            const SizedBox(width: 4),
            Text('${game.myScore}',
              style: const TextStyle(color: AppColors.gold,
                fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    ),
  );
}

class _AnswerOptions extends StatelessWidget {
  final GameState game;
  final WidgetRef ref;
  const _AnswerOptions({required this.game, required this.ref});

  static const _labels   = ['A', 'B', 'C', 'D'];
  static const _colors   = [AppColors.optionA, AppColors.optionB,
                             AppColors.optionC, AppColors.optionD];

  @override
  Widget build(BuildContext context) {
    final question = game.currentRound?.question;
    if (question == null) return const SizedBox.shrink();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: 4,
      itemBuilder: (_, i) {
        final letter = _labels[i];
        final text   = question.optionText(letter);
        final isSelected = game.selectedOption == letter;
        final isCorrect  = game.answerRevealed &&
            letter == question.correctOption;
        final isWrong    = game.answerRevealed && isSelected &&
            letter != question.correctOption;

        Color bgColor = _colors[i];
        if (isCorrect) bgColor = AppColors.success;
        if (isWrong)   bgColor = AppColors.error;

        return GestureDetector(
          onTap: game.hasAnswered ? null : () =>
              ref.read(gameProvider.notifier).submitAnswer(letter),
          child: AnimatedContainer(
            duration: 300.ms,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(letter,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                      color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(text,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ).animate(delay: (i * 80).ms)
           .slideY(begin: 0.3, end: 0, duration: 300.ms)
           .fadeIn(),
        );
      },
    );
  }
}

// ─── Resultado de ronda ───────────────────────────────────────────────────
class _RoundResultView extends StatelessWidget {
  final GameState game;
  const _RoundResultView({required this.game});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          game.lastAnswerCorrect ? Icons.check_circle : Icons.cancel,
          size: 80,
          color: game.lastAnswerCorrect ? AppColors.success : AppColors.error,
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(
          game.lastAnswerCorrect ? '¡Correcto!' : '¡Incorrecto!',
          style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700,
            color: game.lastAnswerCorrect ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(height: 8),
        if (game.lastAnswerCorrect)
          const Text('+10 puntos',
            style: TextStyle(color: AppColors.gold, fontSize: 18,
              fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        Text('Tu puntuación: ${game.myScore}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      ],
    ),
  );
}
