import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../models/room_model.dart';
import '../models/question_model.dart';
import '../models/game_round_model.dart';

class RoomRepository {
  SupabaseClient get _db => SupabaseService.client;

  // ─── Crear sala ───────────────────────────────────────────────────────────
  Future<RoomModel> createRoom({bool isPrivate = false}) async {
    final userId = SupabaseService.currentUserId!;

    final data = await _db.from('rooms').insert({
      'host_id':    userId,
      'room_type':  isPrivate ? 'private' : 'public',
      'max_players': AppConstants.maxPlayersPerRoom,
      'total_rounds': AppConstants.questionsPerGame,
      'waiting_until': DateTime.now()
          .add(const Duration(seconds: AppConstants.waitingRoomSeconds))
          .toUtc()
          .toIso8601String(),
    }).select('''
      *,
      room_players (
        *,
        profiles ( display_name, avatar_url, level_id )
      )
    ''').single();

    // Unirse como host (seat 1)
    await _joinRoom(roomId: data['id'] as String, seat: 1);

    return RoomModel.fromJson(data);
  }

  // ─── Unirse a sala por código ────────────────────────────────────────────
  Future<RoomModel> joinRoomByCode(String code) async {
    final data = await _db.from('rooms')
        .select('''
          *,
          room_players (
            *,
            profiles ( display_name, avatar_url, level_id )
          )
        ''')
        .eq('code', code.toUpperCase())
        .eq('status', 'waiting')
        .single();

    final room = RoomModel.fromJson(data);
    if (room.isFull) throw Exception('La sala está llena');

    final seat = _nextAvailableSeat(room.players);
    await _joinRoom(roomId: room.id, seat: seat);

    return fetchRoom(room.id);
  }

  // ─── Buscar sala pública disponible ─────────────────────────────────────
  Future<RoomModel> findOrCreatePublicRoom() async {
    final rows = await _db.from('rooms')
        .select('id, max_players, room_players(count)')
        .eq('status', 'waiting')
        .eq('room_type', 'public')
        .limit(10);

    for (final row in rows) {
      final count = (row['room_players'] as List).first['count'] as int;
      if (count < AppConstants.maxPlayersPerRoom) {
        try {
          return joinRoomByCode(row['id'] as String);
        } catch (_) { continue; }
      }
    }
    return createRoom();
  }

  // ─── Obtener sala ─────────────────────────────────────────────────────────
  Future<RoomModel> fetchRoom(String roomId) async {
    final data = await _db.from('rooms')
        .select('''
          *,
          room_players (
            *,
            profiles ( display_name, avatar_url, level_id )
          )
        ''')
        .eq('id', roomId)
        .single();
    return RoomModel.fromJson(data);
  }

  // ─── Escuchar cambios en sala (Realtime) ─────────────────────────────────
  RealtimeChannel subscribeToRoom({
    required String roomId,
    required void Function(RoomModel) onRoomUpdate,
    required void Function(RoomPlayerModel) onPlayerUpdate,
    required void Function(GameRoundModel) onNewRound,
  }) {
    final channel = _db.channel('room:$roomId');

    // Cambios en la sala
    channel.onPostgresChanges(
      event:  PostgresChangeEvent.update,
      schema: 'public',
      table:  'rooms',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: roomId),
      callback: (payload) async {
        final room = await fetchRoom(roomId);
        onRoomUpdate(room);
      },
    );

    // Cambios en jugadores
    channel.onPostgresChanges(
      event:  PostgresChangeEvent.all,
      schema: 'public',
      table:  'room_players',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onPlayerUpdate(RoomPlayerModel.fromJson(payload.newRecord));
        }
      },
    );

    // Nueva ronda
    channel.onPostgresChanges(
      event:  PostgresChangeEvent.insert,
      schema: 'public',
      table:  'game_rounds',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
      callback: (payload) async {
        final round = await fetchCurrentRound(roomId);
        if (round != null) onNewRound(round);
      },
    );

    channel.subscribe();
    return channel;
  }

  // ─── Ronda actual ─────────────────────────────────────────────────────────
  Future<GameRoundModel?> fetchCurrentRound(String roomId) async {
    final rows = await _db.from('game_rounds')
        .select('*, questions(*), player_answers(*)')
        .eq('room_id', roomId)
        .isFilter('finished_at', null)
        .order('round_number', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return GameRoundModel.fromJson(rows.first);
  }

  // ─── Enviar respuesta ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitAnswer({
    required String roundId,
    required String roomPlayerId,
    required String selectedOption,
    required int    answerTimeMs,
  }) async {
    // Llama a la Edge Function para validar en servidor
    final response = await _db.functions.invoke('validate-answer', body: {
      'round_id':       roundId,
      'room_player_id': roomPlayerId,
      'selected_option': selectedOption,
      'answer_time_ms':  answerTimeMs,
    });

    if (response.status != 200) {
      throw Exception('Error al enviar respuesta');
    }
    return response.data as Map<String, dynamic>;
  }

  // ─── Agregar bots a sala ──────────────────────────────────────────────────
  Future<void> fillWithBots(String roomId, int botsNeeded) async {
    final room  = await fetchRoom(roomId);
    final taken = room.players.map((p) => p.seatNumber).toSet();

    final bots = AppConstants.botProfiles.take(botsNeeded).toList();
    int seat = 1;

    for (final bot in bots) {
      while (taken.contains(seat)) seat++;
      await _db.from('room_players').insert({
        'room_id':    roomId,
        'is_bot':     true,
        'bot_level':  bot['level'],
        'bot_name':   bot['name'],
        'bot_avatar': bot['avatar'],
        'seat_number': seat,
        'status':     'ready',
      });
      taken.add(seat);
      seat++;
    }
  }

  // ─── Privados ─────────────────────────────────────────────────────────────
  Future<void> _joinRoom({required String roomId, required int seat}) async {
    await _db.from('room_players').insert({
      'room_id':    roomId,
      'user_id':    SupabaseService.currentUserId,
      'is_bot':     false,
      'seat_number': seat,
      'status':     'waiting',
    });
  }

  int _nextAvailableSeat(List<RoomPlayerModel> players) {
    final taken = players.map((p) => p.seatNumber).toSet();
    for (int i = 1; i <= AppConstants.maxPlayersPerRoom; i++) {
      if (!taken.contains(i)) return i;
    }
    throw Exception('No hay asientos disponibles');
  }

  // ─── Obtener preguntas para partida (del caché) ───────────────────────────
  Future<List<QuestionModel>> getQuestionsForGame() async {
    final rows = await _db.rpc('get_game_questions', params: {
      'p_total': AppConstants.questionsPerGame,
    });

    return (rows as List)
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  // ─── Guardar preguntas en caché ───────────────────────────────────────────
  Future<void> cacheQuestions(List<QuestionModel> questions) async {
    final rows = questions.map((q) => {
      'question_text':  q.questionText,
      'option_a':       q.optionA,
      'option_b':       q.optionB,
      'option_c':       q.optionC,
      'option_d':       q.optionD,
      'correct_option': q.correctOption,
      'difficulty':     q.difficulty,
      'category':       q.category,
    }).toList();

    await _db.from('questions').insert(rows);
  }

  Future<int> countCachedQuestions() async {
    final response = await _db.from('questions')
        .select()
        .eq('is_active', true)
        .count(CountOption.exact);
    return response.count ?? 0;
  }
}
