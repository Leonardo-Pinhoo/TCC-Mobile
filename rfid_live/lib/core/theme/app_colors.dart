import 'package:flutter/material.dart';

/// Paleta escura monocromática usada em toda a aplicacao RFID LIVE,
/// alinhada com a identidade visual do site da Atlas (theatlasdev.com.br).
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundTop = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceAlt = Color(0xFF232323);
  static const Color surfaceInput = Color(0xFF161616);
  static const Color border = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color borderStrong = Color.fromRGBO(255, 255, 255, 0.18);

  /// Acento monocromático — usado em FAB, botão principal, foco de campo e
  /// indicador de aba ativa, como os botões em pílula do site da Atlas.
  static const Color primary = Color(0xFFFAFAF8);
  static const Color onPrimary = Color(0xFF0A0A0A);

  /// Cor de texto legível sobre um fundo sólido [background]: preto sobre o
  /// acento branco, branco sobre as cores de status.
  static Color onAccent(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light
          ? onPrimary
          : Colors.white;

  static const Color textPrimary = Color(0xFFFAFAF8);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF5C5C5C);

  /// Cores de status: carregam significado operacional, por isso continuam
  /// coloridas mesmo numa paleta de marca monocromática.
  static const Color inUse = Color(0xFF3B82F6);
  static const Color available = Color(0xFF22C55E);
  static const Color maintenance = Color(0xFFF59E0B);
  static const Color missing = Color(0xFFEF4444);

  static const Color live = Color(0xFF22C55E);
  static const Color critical = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
