import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../../data/models/room_model.dart';
import '../../data/models/game_round_model.dart';
import '../../data/repositories/room_repository.dart';

// ─── Estado del juego ─────────────────────────────────────────────────────
enum GamePhase { idle, lobby, countdown, question, showResults, gameOver }

class GameState {
  final RoomModel?      room;
  final GameRoundModel? currentRound;
  final GamePhase       phase;
  final int             secondsLeft;
  final String?         selectedOption;
  final bool            hasAnswered;
  final bool            answerRevealed;
  final bool            lastAnswerCorrect;
  final int             myScore;
  final String?         error;

  const GameState({
    this.room,
    this.currentRound,
    this.phase         = GamePhase.idle,
    this.secondsLeft   = AppConstants.secondsPerQuestion,
    this.selectedOption,
    this.hasAnswered    = false,
    this.answerRevealed = false,
    this.lastAnswerCorrect = false,
    this.myScore       = 0,
    this.error,
  });

  bool get isMyTurn     => !hasAnswered && phase == GamePhase.question;
  int  get roundNumber  => currentRound?.roundNumber ?? 0;
  int  get totalRounds  => room?.totalRounds ?? AppConstants.questionsPerGame;

  GameState copyWith({
    RoomModel?      room,
    GameRoundModel? currentRound,
    GamePhase?      phase,
    int?            secondsLeft,
    String?         selectedOption,
    bool?           hasAnswered,
    bool?           answerRevealed,
    bool?           lastAnswerCorrect,
    int?            myScore,
    String?         error,
  }) => GameState(
    room:              room              ?? this.room,
    currentRound:      currentRound      ?? this.currentRound,
    phase:             phase             ?? this.phase,
    secondsLeft:       secondsLeft       ?? this.secondsLeft,
    selectedOption:    selectedOption    ?? this.selectedOption,
    hasAnswered:       hasAnswered       ?? this.hasAnswered,
    answerRevealed:    answerRevealed    ?? this.answerRevealed,
    lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
    myScore:           myScore           ?? this.myScore,
    error:             error,
  );

  GameState resetForNewRound() => GameState(
    room:        room,
    currentRound: currentRound,
    phase:       GamePhase.question,
    secondsLeft: AppConstants.secondsPerQuestion,
    myScore:     myScore,
  );
}

// ─── Provider ────────────────────────────────────────────────────────────
class GameNotifier extends StateNotifier<GameState> {
  final RoomRepository _repo;
  RealtimeChannel?     _channel;
  Timer?               _timer;
  String?              _myRoomPlayerId;
  DateTime?            _roundStartTime;

  GameNotifier(this._repo) : super(const GameState());

  // ── Crear sala ─────────────────────────────────────────────────────────
  Future<void> createRoom({bool isPrivate = false}) async {
    try {
      final room = await _repo.createRoom(isPrivate: isPrivate);
      state = state.copyWith(room: room, phase: GamePhase.lobby);
      _subscribeToRoom(room.id);
      _scheduleBotsIfNeeded(room);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Unirse por código ──────────────────────────────────────────────────
  Future<void> joinByCode(String code) async {
    try {
      final room = await _repo.joinRoomByCode(code);
      state = state.copyWith(room: room, phase: GamePhase.lobby);
      _subscribeToRoom(room.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Buscar sala pública ────────────────────────────────────────────────
  Future<void> findPublicRoom() async {
    try {
      final room = await _repo.findOrCreatePublicRoom();
      state = state.copyWith(room: room, phase: GamePhase.lobby);
      _subscribeToRoom(room.id);
      _scheduleBotsIfNeeded(room);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Responder pregunta ─────────────────────────────────────────────────
  Future<void> submitAnswer(String option) async {
    if (state.hasAnswered || state.phase != GamePhase.question) return;
    if (_myRoomPlayerId == null || state.currentRound == null) return;

    final elapsed = _roundStartTime != null
        ? DateTime.now().difference(_roundStartTime!).inMilliseconds
        : 0;

    state = state.copyWith(
      selectedOption: option,
      hasAnswered:    true,
    );

    try {
      final result = await _repo.submitAnswer(
        roundId:        state.currentRound!.id,
        roomPlayerId:   _myRoomPlayerId!,
        selectedOption: option,
        answerTimeMs:   elapsed,
      );

      final isCorrect = result['is_correct'] as bool;
      final pts       = result['points_earned'] as int;

      state = state.copyWith(
        answerRevealed:    true,
        lastAnswerCorrect: isCorrect,
        myScore:           state.myScore + pts,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Suscripción Realtime ───────────────────────────────────────────────
  void _subscribeToRoom(String roomId) {
    _channel = _repo.subscribeToRoom(
      roomId:         roomId,
      onRoomUpdate:   _handleRoomUpdate,
      onPlayerUpdate: _handlePlayerUpdate,
      onNewRound:     _handleNewRound,
    );
  }

  void _handleRoomUpdate(RoomModel room) {
    state = state.copyWith(room: room);

    if (room.status == RoomStatus.inProgress && state.phase == GamePhase.lobby) {
      state = state.copyWith(phase: GamePhase.countdown);
    } else if (room.status == RoomStatus.finished) {
      _stopTimer();
      state = state.copyWith(phase: GamePhase.gameOver);
    }
  }

  void _handlePlayerUpdate(RoomPlayerModel player) {
    final room = state.room;
    if (room == null) return;

    final updatedPlayers = room.players.map((p) =>
      p.id == player.id ? player : p
    ).toList();

    if (!updatedPlayers.any((p) => p.id == player.id)) {
      updatedPlayers.add(player);
    }

    state = state.copyWith(room: room.copyWith(players: updatedPlayers));

    // Resolver mi roomPlayerId
    final userId = SupabaseService.currentUserId;
    _myRoomPlayerId ??= updatedPlayers
        .firstWhere((p) => p.userId == userId, orElse: () => player)
        .id;
  }

  void _handleNewRound(GameRoundModel round) {
    _stopTimer();
    _roundStartTime = DateTime.now();
    state = state.copyWith(
      currentRound:   round,
      phase:          GamePhase.question,
      secondsLeft:    AppConstants.secondsPerQuestion,
      hasAnswered:    false,
      answerRevealed: false,
      selectedOption: null,
    );
    _startCountdown();
  }

  // ── Timer de pregunta ──────────────────────────────────────────────────
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.secondsLeft - 1;
      if (left <= 0) {
        _stopTimer();
        if (!state.hasAnswered) {
          state = state.copyWith(
            secondsLeft:    0,
            hasAnswered:    true,
            answerRevealed: true,
          );
        }
      } else {
        state = state.copyWith(secondsLeft: left);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Bots automáticos ───────────────────────────────────────────────────
  void _scheduleBotsIfNeeded(RoomModel room) {
    Timer(const Duration(seconds: AppConstants.waitingRoomSeconds), () async {
      if (state.phase != GamePhase.lobby) return;
      final current = await _repo.fetchRoom(room.id);
      final humanCount = current.players.where((p) => p.isHuman).length;
      if (humanCount < AppConstants.minPlayersToStart) {
        final botsNeeded = AppConstants.minPlayersToStart - humanCount;
        await _repo.fillWithBots(room.id, botsNeeded);
      }
    });
  }

  void clearError() => state = state.copyWith(error: null);

  @override
  void dispose() {
    _stopTimer();
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────
final roomRepositoryProvider = Provider<RoomRepository>((_) => RoomRepository());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref.read(roomRepositoryProvider));
});
