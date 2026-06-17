enum RoomStatus { waiting, starting, inProgress, finished, cancelled }
enum RoomType   { public, private }

class RoomPlayerModel {
  final String  id;
  final String  roomId;
  final String? userId;
  final bool    isBot;
  final String? botLevel;
  final String? botName;
  final String? botAvatar;
  final String  status;
  final int     seatNumber;
  final int     score;
  final int     correctAnswers;
  final int     streak;
  final int?    finalRank;
  final int?    pointsEarned;

  // Datos del perfil (join)
  final String? displayName;
  final String? avatarUrl;
  final int?    levelId;

  const RoomPlayerModel({
    required this.id,
    required this.roomId,
    this.userId,
    required this.isBot,
    this.botLevel,
    this.botName,
    this.botAvatar,
    required this.status,
    required this.seatNumber,
    required this.score,
    required this.correctAnswers,
    required this.streak,
    this.finalRank,
    this.pointsEarned,
    this.displayName,
    this.avatarUrl,
    this.levelId,
  });

  String get name => isBot ? (botName ?? 'Bot') : (displayName ?? 'Jugador');
  String? get avatar => isBot ? botAvatar : avatarUrl;
  bool get isHuman => !isBot;

  factory RoomPlayerModel.fromJson(Map<String, dynamic> json) => RoomPlayerModel(
    id:             json['id'] as String,
    roomId:         json['room_id'] as String,
    userId:         json['user_id'] as String?,
    isBot:          json['is_bot'] as bool,
    botLevel:       json['bot_level'] as String?,
    botName:        json['bot_name'] as String?,
    botAvatar:      json['bot_avatar'] as String?,
    status:         json['status'] as String,
    seatNumber:     json['seat_number'] as int,
    score:          json['score'] as int,
    correctAnswers: json['correct_answers'] as int,
    streak:         json['streak'] as int,
    finalRank:      json['final_rank'] as int?,
    pointsEarned:   json['points_earned'] as int?,
    displayName:    json['profiles']?['display_name'] as String?,
    avatarUrl:      json['profiles']?['avatar_url'] as String?,
    levelId:        json['profiles']?['level_id'] as int?,
  );

  RoomPlayerModel copyWith({
    int?    score,
    int?    correctAnswers,
    int?    streak,
    int?    finalRank,
    int?    pointsEarned,
    String? status,
  }) => RoomPlayerModel(
    id:             id,
    roomId:         roomId,
    userId:         userId,
    isBot:          isBot,
    botLevel:       botLevel,
    botName:        botName,
    botAvatar:      botAvatar,
    status:         status         ?? this.status,
    seatNumber:     seatNumber,
    score:          score          ?? this.score,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    streak:         streak         ?? this.streak,
    finalRank:      finalRank      ?? this.finalRank,
    pointsEarned:   pointsEarned   ?? this.pointsEarned,
    displayName:    displayName,
    avatarUrl:      avatarUrl,
    levelId:        levelId,
  );
}

class RoomModel {
  final String     id;
  final String     code;
  final String?    hostId;
  final RoomStatus status;
  final RoomType   roomType;
  final int        maxPlayers;
  final int        currentRound;
  final int        totalRounds;
  final DateTime?  waitingUntil;
  final DateTime?  startedAt;
  final DateTime?  finishedAt;
  final DateTime   createdAt;
  final List<RoomPlayerModel> players;

  const RoomModel({
    required this.id,
    required this.code,
    this.hostId,
    required this.status,
    required this.roomType,
    required this.maxPlayers,
    required this.currentRound,
    required this.totalRounds,
    this.waitingUntil,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    this.players = const [],
  });

  int get playerCount   => players.length;
  bool get isFull       => playerCount >= maxPlayers;
  bool get canStart     => playerCount >= 2;
  bool get isWaiting    => status == RoomStatus.waiting;
  bool get isInProgress => status == RoomStatus.inProgress;
  bool get isFinished   => status == RoomStatus.finished;

  List<RoomPlayerModel> get sortedPlayers =>
      [...players]..sort((a, b) => b.score.compareTo(a.score));

  static RoomStatus _parseStatus(String s) {
    switch (s) {
      case 'waiting':     return RoomStatus.waiting;
      case 'starting':    return RoomStatus.starting;
      case 'in_progress': return RoomStatus.inProgress;
      case 'finished':    return RoomStatus.finished;
      default:            return RoomStatus.cancelled;
    }
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    id:           json['id'] as String,
    code:         json['code'] as String,
    hostId:       json['host_id'] as String?,
    status:       _parseStatus(json['status'] as String),
    roomType:     json['room_type'] == 'private' ? RoomType.private : RoomType.public,
    maxPlayers:   json['max_players'] as int,
    currentRound: json['current_round'] as int,
    totalRounds:  json['total_rounds'] as int,
    waitingUntil: json['waiting_until'] != null ? DateTime.parse(json['waiting_until']) : null,
    startedAt:    json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
    finishedAt:   json['finished_at'] != null ? DateTime.parse(json['finished_at']) : null,
    createdAt:    DateTime.parse(json['created_at'] as String),
    players:      (json['room_players'] as List<dynamic>?)
                    ?.map((p) => RoomPlayerModel.fromJson(p as Map<String, dynamic>))
                    .toList() ?? [],
  );

  RoomModel copyWith({
    RoomStatus?             status,
    int?                    currentRound,
    List<RoomPlayerModel>?  players,
    DateTime?               startedAt,
    DateTime?               finishedAt,
  }) => RoomModel(
    id:           id,
    code:         code,
    hostId:       hostId,
    status:       status       ?? this.status,
    roomType:     roomType,
    maxPlayers:   maxPlayers,
    currentRound: currentRound ?? this.currentRound,
    totalRounds:  totalRounds,
    waitingUntil: waitingUntil,
    startedAt:    startedAt    ?? this.startedAt,
    finishedAt:   finishedAt   ?? this.finishedAt,
    createdAt:    createdAt,
    players:      players      ?? this.players,
  );
}
