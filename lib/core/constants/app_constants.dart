class AppConstants {
  AppConstants._();

  // Juego
  static const int questionsPerGame     = 10;
  static const int secondsPerQuestion   = 15;
  static const int waitingRoomSeconds   = 30;
  static const int maxPlayersPerRoom    = 4;
  static const int minPlayersToStart    = 2;
  static const int botsToFill          = 3; // si no hay humanos suficientes

  // Puntos por posición
  static const Map<int, int> pointsByRank = {
    1: 100,
    2: 60,
    3: 30,
    4: 10,
  };

  // Multiplicadores
  static const int pointsPerCorrectAnswer = 10;
  static const int pointsStreakBonus      = 5;   // cada 3 correctas seguidas
  static const int pointsPerfectGame      = 20;  // todas correctas
  static const int streakThreshold        = 3;

  // Niveles (puntos mínimos)
  static const Map<int, int> levelMinPoints = {
    1: 0,
    2: 1000,
    3: 5000,
    4: 15000,
  };

  static const Map<int, String> levelNames = {
    1: 'Aspirante',
    2: 'Saber',
    3: 'Élite',
    4: 'Leyenda Milton Ochoa',
  };

  // Distribución de dificultad (%)
  static const double easyPercent   = 0.30;
  static const double mediumPercent = 0.40;
  static const double hardPercent   = 0.30;

  // Comodines diarios
  static const int dailyPowerupsEach = 1;

  // Caché de preguntas
  static const int minQuestionsCache = 50; // mínimo antes de regenerar

  // Supabase canales
  static const String channelRoom     = 'room:';
  static const String channelPresence = 'presence:';

  // Bots
  static const List<Map<String, dynamic>> botProfiles = [
    {'name': 'Carlos Bot',   'avatar': 'bot_1', 'level': 'novato',   'accuracy': 0.45, 'minMs': 8000,  'maxMs': 14000},
    {'name': 'María Bot',    'avatar': 'bot_2', 'level': 'promedio', 'accuracy': 0.65, 'minMs': 5000,  'maxMs': 11000},
    {'name': 'Andrés Bot',   'avatar': 'bot_3', 'level': 'experto',  'accuracy': 0.85, 'minMs': 2000,  'maxMs': 7000},
    {'name': 'Valentina Bot','avatar': 'bot_4', 'level': 'promedio', 'accuracy': 0.60, 'minMs': 6000,  'maxMs': 12000},
    {'name': 'Felipe Bot',   'avatar': 'bot_5', 'level': 'novato',   'accuracy': 0.40, 'minMs': 9000,  'maxMs': 15000},
  ];

  // Categorías de preguntas
  static const List<String> questionCategories = [
    'Ciencia',
    'Historia',
    'Geografía',
    'Tecnología',
    'Arte y Cultura',
    'Entretenimiento',
    'Matemáticas',
    'Colombia y Latinoamérica',
    'Deportes',
    'Literatura',
  ];
}
