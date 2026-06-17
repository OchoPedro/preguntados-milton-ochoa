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
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.15),
          ),
          child: Center(
            child: CustomPaint(
              size: Size(size * 0.72, size * 0.72),
              painter: _MoLogoPainter(),
            ),
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.12),
          Text(
            'Milton Ochoa',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: size * 0.175,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'Expertos en Evaluación',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: size * 0.1,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _MoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.095
      ..strokeCap = StrokeCap.round;

    // M letter (left side)
    final mPath = Path();
    mPath.moveTo(size.width * 0.0, size.height * 0.75);
    mPath.lineTo(size.width * 0.0, size.height * 0.18);
    mPath.quadraticBezierTo(
      size.width * 0.0, size.height * 0.0,
      size.width * 0.18, size.height * 0.0,
    );
    mPath.quadraticBezierTo(
      size.width * 0.36, size.height * 0.0,
      size.width * 0.36, size.height * 0.18,
    );
    mPath.lineTo(size.width * 0.36, size.height * 0.75);
    canvas.drawPath(mPath, paint);

    // O letter with exclamation (right side)
    final center = Offset(size.width * 0.72, size.height * 0.38);
    final radius = size.width * 0.26;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.4,
      5.4,
      false,
      paint,
    );

    // Exclamation dot inside O
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.38),
      size.width * 0.05,
      dotPaint,
    );

    // Exclamation line
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.18),
      Offset(size.width * 0.72, size.height * 0.28),
      paint..strokeWidth = size.width * 0.06,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
