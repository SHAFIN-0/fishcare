import 'package:flutter/material.dart';

/// Colors sampled from the FishCare mockup: deep navy background, teal->blue
/// gradient brand identity, dark cards, and red/green status accents.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A1420);
  static const Color surface = Color(0xFF122029);
  static const Color surfaceAlt = Color(0xFF17262F);
  static const Color border = Color(0xFF223038);

  static const Color tealStart = Color(0xFF22C3B0);
  static const Color tealEnd = Color(0xFF2E6FE0);
  static const Color teal = Color(0xFF1FB8A8);
  static const Color tealDim = Color(0xFF14A899);

  static const Color textPrimary = Color(0xFFEAF3F1);
  static const Color textSecondary = Color(0xFF8FA3A0);
  static const Color textMuted = Color(0xFF5E7370);

  static const Color danger = Color(0xFFE0483F);
  static const Color dangerBg = Color(0xFF3A2020);
  static const Color success = Color(0xFF2ECC8F);
  static const Color successBg = Color(0xFF17332A);
  static const Color warning = Color(0xFFE0A83F);
  static const Color warningBg = Color(0xFF3A3020);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealStart, tealEnd],
  );
}
