enum PowerupType { fiftyFifty, extraTime, skip }

class ChallengeModel {
  final String      id;
  final String      title;
  final String      description;
  final Map<String, dynamic> requirement; // {"type": "win_count", "value": 3}
  final PowerupType rewardType;
  final int         rewardQty;
  final bool        isActive;

  // Progreso del usuario (viene del join con user_challenges)
  final int?        userProgress;
  final DateTime?   completedAt;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.rewardType,
    required this.rewardQty,
    required this.isActive,
    this.userProgress,
    this.completedAt,
  });

  int get targetValue => requirement['value'] as int? ?? 1;
  bool get isCompleted => completedAt != null;
  int  get progress    => userProgress ?? 0;

  double get progressPercent =>
      (progress / targetValue).clamp(0.0, 1.0).toDouble();

  String get rewardLabel => switch (rewardType) {
    PowerupType.fiftyFifty => '50/50',
    PowerupType.extraTime  => '+10s',
    PowerupType.skip       => 'Saltar',
  };

  String get requirementLabel {
    final type  = requirement['type'] as String? ?? '';
    final value = requirement['value'] as int?    ?? 0;
    return switch (type) {
      'win_count'       => 'Ganar $value partida${value > 1 ? 's' : ''}',
      'win_streak'      => 'Ganar $value partidas seguidas',
      'answer_streak'   => 'Responder $value preguntas seguidas correctamente',
      'correct_answers' => 'Responder $value preguntas correctas en total',
      'games_played'    => 'Jugar $value partidas',
      _                 => description,
    };
  }

  static PowerupType _parsePowerup(String s) => switch (s) {
    'extra_time'   => PowerupType.extraTime,
    'skip'         => PowerupType.skip,
    _              => PowerupType.fiftyFifty,
  };

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final userChallenge = json['user_challenges'] as List?;
    final uc = userChallenge?.isNotEmpty == true ? userChallenge!.first as Map<String, dynamic> : null;

    return ChallengeModel(
      id:           json['id'] as String,
      title:        json['title'] as String,
      description:  json['description'] as String,
      requirement:  json['requirement'] as Map<String, dynamic>,
      rewardType:   _parsePowerup(json['reward_type'] as String),
      rewardQty:    json['reward_qty'] as int,
      isActive:     json['is_active'] as bool,
      userProgress: uc?['progress'] as int?,
      completedAt:  uc?['completed_at'] != null
          ? DateTime.parse(uc!['completed_at'] as String)
          : null,
    );
  }
}
