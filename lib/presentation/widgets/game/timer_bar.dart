import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TimerBar extends StatelessWidget {
  final int secondsLeft;
  final int total;

  const TimerBar({super.key, required this.secondsLeft, required this.total});

  Color get _color {
    final pct = secondsLeft / total;
    if (pct > 0.5) return AppColors.success;
    if (pct > 0.25) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.timer, size: 14, color: AppColors.textHint),
            Text('$secondsLeft s',
              style: TextStyle(color: _color, fontSize: 13,
                fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: secondsLeft / total,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(_color),
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}
