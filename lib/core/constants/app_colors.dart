import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Colores corporativos Milton Ochoa
  static const Color primary        = Color(0xFF0A1F3D); // Azul marino corporativo
  static const Color primaryLight   = Color(0xFF163460); // Azul marino claro
  static const Color primaryDark    = Color(0xFF060F1E); // Azul marino muy oscuro
  static const Color accent         = Color(0xFF2D9B6F); // Verde corporativo
  static const Color accentLight    = Color(0xFF3DB880); // Verde claro
  static const Color accentDark     = Color(0xFF1F7A52); // Verde oscuro

  // Compatibilidad backward (alias)
  static const Color gold           = Color(0xFF2D9B6F); // Verde corporativo (reemplaza dorado)
  static const Color goldLight      = Color(0xFF3DB880);
  static const Color goldDark       = Color(0xFF1F7A52);

  // Niveles
  static const Color levelAspirante = Color(0xFF8BA8C3);
  static const Color levelSaber     = Color(0xFF2D9B6F);
  static const Color levelElite     = Color(0xFF163460);
  static const Color levelLeyenda   = Color(0xFF0A1F3D);

  // UI General
  static const Color background     = Color(0xFF060F1E); // Fondo oscuro basado en azul corporativo
  static const Color surface        = Color(0xFF0D1E35);
  static const Color surfaceLight   = Color(0xFF163252);
  static const Color cardBg         = Color(0xFF0A1F3D);

  // Texto
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFB8D0E8);
  static const Color textHint       = Color(0xFF7A99B8);

  // Estados
  static const Color success        = Color(0xFF2D9B6F); // Verde corporativo
  static const Color successLight   = Color(0xFF3DB880);
  static const Color error          = Color(0xFFEF5350);
  static const Color errorLight     = Color(0xFFE57373);
  static const Color warning        = Color(0xFFFF9800);
  static const Color info           = Color(0xFF29B6F6);

  // Opciones de respuesta (A, B, C, D) — variantes de los colores corporativos
  static const Color optionA        = Color(0xFF163460); // Azul corporativo medio
  static const Color optionB        = Color(0xFF1F7A52); // Verde corporativo oscuro
  static const Color optionC        = Color(0xFF0A2E55); // Azul corporativo oscuro
  static const Color optionD        = Color(0xFF0F5C40); // Verde corporativo muy oscuro

  // Dificultad
  static const Color diffEasy       = Color(0xFF2D9B6F); // Verde corporativo
  static const Color diffMedium     = Color(0xFFFF9800);
  static const Color diffHard       = Color(0xFFEF5350);

  // Bordes
  static const Color border         = Color(0xFF163460);
  static const Color borderLight    = Color(0xFF1E4A7A);

  // Overlay
  static const Color overlay        = Color(0x80000000);
  static const Color overlayLight   = Color(0x40000000);
}
