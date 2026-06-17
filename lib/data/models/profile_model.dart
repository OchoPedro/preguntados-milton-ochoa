import '../../core/constants/app_constants.dart';

class ProfileModel {
  final String  id;
  final String  username;
  final String  displayName;
  final String? avatarUrl;
  final int     totalPoints;
  final int     levelId;
  final int     gamesPlayed;
  final int     gamesWon;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.levelId,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.createdAt,
  });

  String get levelName => AppConstants.levelNames[levelId] ?? 'Aspirante';

  int get nextLevelPoints {
    final nextLevel = levelId + 1;
    return AppConstants.levelMinPoints[nextLevel] ?? totalPoints;
  }

  double get levelProgress {
    if (levelId >= 4) return 1.0;
    final current  = AppConstants.levelMinPoints[levelId]!;
    final next     = AppConstants.levelMinPoints[levelId + 1]!;
    return ((totalPoints - current) / (next - current)).clamp(0.0, 1.0);
  }

  int get pointsToNextLevel {
    if (levelId >= 4) return 0;
    return nextLevelPoints - totalPoints;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id:           json['id'] as String,
    username:     json['username'] as String,
    displayName:  json['display_name'] as String,
    avatarUrl:    json['avatar_url'] as String?,
    totalPoints:  json['total_points'] as int,
    levelId:      json['level_id'] as int,
    gamesPlayed:  json['games_played'] as int,
    gamesWon:     json['games_won'] as int,
    createdAt:    DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'username':     username,
    'display_name': displayName,
    'avatar_url':   avatarUrl,
    'total_points': totalPoints,
    'level_id':     levelId,
    'games_played': gamesPlayed,
    'games_won':    gamesWon,
    'created_at':   createdAt.toIso8601String(),
  };

  ProfileModel copyWith({
    String?  username,
    String?  displayName,
    String?  avatarUrl,
    int?     totalPoints,
    int?     levelId,
    int?     gamesPlayed,
    int?     gamesWon,
  }) => ProfileModel(
    id:           id,
    username:     username     ?? this.username,
    displayName:  displayName  ?? this.displayName,
    avatarUrl:    avatarUrl    ?? this.avatarUrl,
    totalPoints:  totalPoints  ?? this.totalPoints,
    levelId:      levelId      ?? this.levelId,
    gamesPlayed:  gamesPlayed  ?? this.gamesPlayed,
    gamesWon:     gamesWon     ?? this.gamesWon,
    createdAt:    createdAt,
  );
}
