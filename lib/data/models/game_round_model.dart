import 'question_model.dart';

class PlayerAnswerModel {
  final String  id;
  final String  roundId;
  final String  roomPlayerId;
  final String? selectedOption;
  final bool?   isCorrect;
  final int?    answerTimeMs;
  final int     pointsEarned;
  final DateTime? answeredAt;

  const PlayerAnswerModel({
    required this.id,
    required this.roundId,
    required this.roomPlayerId,
    this.selectedOption,
    this.isCorrect,
    this.answerTimeMs,
    required this.pointsEarned,
    this.answeredAt,
  });

  bool get hasAnswered => selectedOption != null;

  factory PlayerAnswerModel.fromJson(Map<String, dynamic> json) => PlayerAnswerModel(
    id:             json['id'] as String,
    roundId:        json['round_id'] as String,
    roomPlayerId:   json['room_player_id'] as String,
    selectedOption: json['selected_option'] as String?,
    isCorrect:      json['is_correct'] as bool?,
    answerTimeMs:   json['answer_time_ms'] as int?,
    pointsEarned:   json['points_earned'] as int? ?? 0,
    answeredAt:     json['answered_at'] != null
                      ? DateTime.parse(json['answered_at'] as String)
                      : null,
  );
}

class GameRoundModel {
  final String         id;
  final String         roomId;
  final int            roundNumber;
  final String         questionId;
  final DateTime?      startedAt;
  final DateTime?      endsAt;
  final DateTime?      finishedAt;
  final QuestionModel? question;
  final List<PlayerAnswerModel> answers;

  const GameRoundModel({
    required this.id,
    required this.roomId,
    required this.roundNumber,
    required this.questionId,
    this.startedAt,
    this.endsAt,
    this.finishedAt,
    this.question,
    this.answers = const [],
  });

  bool get isActive   => startedAt != null && finishedAt == null;
  bool get isFinished => finishedAt != null;

  Duration get timeRemaining {
    if (endsAt == null) return Duration.zero;
    final remaining = endsAt!.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int get secondsRemaining => timeRemaining.inSeconds;

  factory GameRoundModel.fromJson(Map<String, dynamic> json) => GameRoundModel(
    id:          json['id'] as String,
    roomId:      json['room_id'] as String,
    roundNumber: json['round_number'] as int,
    questionId:  json['question_id'] as String,
    startedAt:   json['started_at']  != null ? DateTime.parse(json['started_at']) : null,
    endsAt:      json['ends_at']     != null ? DateTime.parse(json['ends_at']) : null,
    finishedAt:  json['finished_at'] != null ? DateTime.parse(json['finished_at']) : null,
    question:    json['questions'] != null
                   ? QuestionModel.fromJson(json['questions'] as Map<String, dynamic>)
                   : null,
    answers:     (json['player_answers'] as List<dynamic>?)
                   ?.map((a) => PlayerAnswerModel.fromJson(a as Map<String, dynamic>))
                   .toList() ?? [],
  );
}
