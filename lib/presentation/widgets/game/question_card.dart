import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/question_model.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final int roundNumber;
  final int totalRounds;

  const QuestionCard({
    super.key,
    required this.question,
    required this.roundNumber,
    required this.totalRounds,
  });

  Color get _difficultyColor => switch (question.difficulty) {
    1 => AppColors.diffEasy,
    2 => AppColors.diffMedium,
    _ => AppColors.diffHard,
  };

  String get _difficultyLabel => switch (question.difficulty) {
    1 => 'Fácil',
    2 => 'Media',
    _ => 'Difícil',
  };

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _difficultyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _difficultyColor.withOpacity(0.5)),
              ),
              child: Text(_difficultyLabel,
                style: TextStyle(color: _difficultyColor, fontSize: 10,
                  fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(question.category,
                style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
            ),
            const Spacer(),
            Text('$roundNumber / $totalRounds',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.questionText,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
