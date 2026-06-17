import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MoLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const MoLogo({super.key, this.size = 120, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_mo.png',
          width: size,
          height: size * 0.78,
          fit: BoxFit.contain,
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.08),
          Text(
            'Preguntados',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: size * 0.2,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'Milton Ochoa',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: size * 0.13,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
              letterSpacing: 2.5,
            ),
          ),
          Text(
            'Expertos en Evaluación',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: size * 0.085,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
