class QuestionModel {
  final String id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final int    difficulty;
  final String category;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.difficulty,
    required this.category,
  });

  String optionText(String letter) {
    switch (letter) {
      case 'A': return optionA;
      case 'B': return optionB;
      case 'C': return optionC;
      case 'D': return optionD;
      default:  return '';
    }
  }

  bool isCorrect(String selected) => selected == correctOption;

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
    id:            json['id'] as String,
    questionText:  json['question_text'] as String,
    optionA:       json['option_a'] as String,
    optionB:       json['option_b'] as String,
    optionC:       json['option_c'] as String,
    optionD:       json['option_d'] as String,
    correctOption: json['correct_option'] as String,
    difficulty:    json['difficulty'] as int,
    category:      json['category'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'question_text':  questionText,
    'option_a':       optionA,
    'option_b':       optionB,
    'option_c':       optionC,
    'option_d':       optionD,
    'correct_option': correctOption,
    'difficulty':     difficulty,
    'category':       category,
  };

  // Versión sin respuesta correcta para enviar a jugadores
  Map<String, dynamic> toPublicJson() => {
    'id':            id,
    'question_text': questionText,
    'option_a':      optionA,
    'option_b':      optionB,
    'option_c':      optionC,
    'option_d':      optionD,
    'difficulty':    difficulty,
    'category':      category,
  };
}
