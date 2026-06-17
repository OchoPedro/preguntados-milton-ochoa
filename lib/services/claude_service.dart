import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/utils/env.dart';
import '../data/models/question_model.dart';

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model   = 'claude-haiku-4-5-20251001';

  static Future<List<QuestionModel>> generateQuestions({
    required int count,
    required int difficulty,
    String? category,
  }) async {
    final cat = category ?? AppConstants.questionCategories[
      DateTime.now().millisecond % AppConstants.questionCategories.length
    ];

    final diffLabel = difficulty == 1 ? 'fácil'
                    : difficulty == 2 ? 'media'
                    : 'difícil';

    final prompt = '''
Genera exactamente $count preguntas de trivia de cultura general.
- Categoría: $cat
- Dificultad: $diffLabel (nivel $difficulty de 3)
- Cada pregunta debe tener 4 opciones (A, B, C, D) con SOLO una correcta
- Las preguntas deben ser apropiadas para jóvenes colombianos
- Varía el tipo: datos históricos, ciencia, geografía, cultura pop, etc.

Responde ÚNICAMENTE con un JSON array con este formato exacto, sin texto adicional:
[
  {
    "question_text": "¿...?",
    "option_a": "...",
    "option_b": "...",
    "option_c": "...",
    "option_d": "...",
    "correct_option": "A",
    "difficulty": $difficulty,
    "category": "$cat"
  }
]
''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type':  'application/json',
        'x-api-key':      Env.claudeApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode}');
    }

    final data      = jsonDecode(response.body) as Map<String, dynamic>;
    final content   = (data['content'] as List).first['text'] as String;

    // Extraer el JSON del response
    final jsonStart = content.indexOf('[');
    final jsonEnd   = content.lastIndexOf(']') + 1;
    final jsonStr   = content.substring(jsonStart, jsonEnd);

    final List<dynamic> questionsJson = jsonDecode(jsonStr);

    return questionsJson
        .asMap()
        .map((i, q) => MapEntry(i, QuestionModel(
          id:            'gen_${DateTime.now().millisecondsSinceEpoch}_$i',
          questionText:  q['question_text'] as String,
          optionA:       q['option_a'] as String,
          optionB:       q['option_b'] as String,
          optionC:       q['option_c'] as String,
          optionD:       q['option_d'] as String,
          correctOption: (q['correct_option'] as String).toUpperCase(),
          difficulty:    q['difficulty'] as int,
          category:      q['category'] as String,
        )))
        .values
        .toList();
  }

  // Generar batch para caché: 30% fácil, 40% medio, 30% difícil
  static Future<List<QuestionModel>> generateBatchForCache({int total = 30}) async {
    final easy   = (total * AppConstants.easyPercent).round();
    final medium = (total * AppConstants.mediumPercent).round();
    final hard   = total - easy - medium;

    final results = await Future.wait([
      generateQuestions(count: easy,   difficulty: 1),
      generateQuestions(count: medium, difficulty: 2),
      generateQuestions(count: hard,   difficulty: 3),
    ]);

    return results.expand((q) => q).toList();
  }
}
