import 'package:flutter/material.dart';

/// Paleta de um tema, exposta pelo [ThemeData] como [ThemeExtension].
///
/// Os tokens de superfície e de conteúdo vêm da identidade da Atlas
/// (theatlasdev.com.br), que define o tema claro invertendo as mesmas
/// variáveis do escuro. As cores de status são do app e ganham um tom próprio
/// no tema claro, porque os valores do escuro não alcançam o contraste mínimo
/// sobre fundo claro.
///
/// Lido pelos widgets através de `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundTop,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceInput,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.inUse,
    required this.available,
    required this.maintenance,
    required this.missing,
    required this.live,
    required this.critical,
    required this.warning,
    required this.info,
  });

  // Superfícies.
  final Color background;
  final Color backgroundTop;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceInput;
  final Color border;
  final Color borderStrong;

  // Conteúdo. O acento é monocromático, como as pílulas do site.
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Status: carregam significado operacional, por isso continuam coloridos
  // numa paleta de marca monocromática.
  final Color inUse;
  final Color available;
  final Color maintenance;
  final Color missing;
  final Color live;
  final Color critical;
  final Color warning;
  final Color info;

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A0A0A),
    backgroundTop: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    surfaceAlt: Color(0xFF232323),
    surfaceInput: Color(0xFF161616),
    border: Color.fromRGBO(255, 255, 255, 0.08),
    borderStrong: Color.fromRGBO(255, 255, 255, 0.18),
    primary: Color(0xFFFAFAF8),
    onPrimary: Color(0xFF0A0A0A),
    textPrimary: Color(0xFFFAFAF8),
    textSecondary: Color(0xFF8A8A8A),
    textMuted: Color(0xFF5C5C5C),
    inUse: Color(0xFF3B82F6),
    available: Color(0xFF22C55E),
    maintenance: Color(0xFFF59E0B),
    missing: Color(0xFFEF4444),
    live: Color(0xFF22C55E),
    critical: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFFAFAF8),
    backgroundTop: Color(0xFFF0F0F0),
    surface: Color(0xFFE8E8E8),
    surfaceAlt: Color(0xFFD8D8D8),
    surfaceInput: Color(0xFFF2F2F0),
    border: Color.fromRGBO(0, 0, 0, 0.10),
    borderStrong: Color.fromRGBO(0, 0, 0, 0.22),
    primary: Color(0xFF0A0A0A),
    onPrimary: Color(0xFFFAFAF8),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF666666),
    textMuted: Color(0xFF888888),
    // Tons escurecidos: os do tema escuro ficam entre 2,06:1 e 3,60:1 sobre
    // #FAFAF8, abaixo do mínimo AA de 4,5:1.
    inUse: Color(0xFF1D4ED8),
    available: Color(0xFF15803D),
    maintenance: Color(0xFFB45309),
    missing: Color(0xFFB91C1C),
    live: Color(0xFF15803D),
    critical: Color(0xFFB91C1C),
    warning: Color(0xFFB45309),
    info: Color(0xFF1D4ED8),
  );

  /// Cor de texto legível sobre um fundo sólido: o [onPrimary] sobre o acento
  /// claro, branco sobre as cores de status.
  Color onAccent(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light
          ? onPrimary
          : Colors.white;

  @override
  AppPalette copyWith({
    Color? background,
    Color? backgroundTop,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceInput,
    Color? border,
    Color? borderStrong,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? inUse,
    Color? available,
    Color? maintenance,
    Color? missing,
    Color? live,
    Color? critical,
    Color? warning,
    Color? info,
  }) {
    return AppPalette(
      background: background ?? this.background,
      backgroundTop: backgroundTop ?? this.backgroundTop,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceInput: surfaceInput ?? this.surfaceInput,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      inUse: inUse ?? this.inUse,
      available: available ?? this.available,
      maintenance: maintenance ?? this.maintenance,
      missing: missing ?? this.missing,
      live: live ?? this.live,
      critical: critical ?? this.critical,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      backgroundTop: mix(backgroundTop, other.backgroundTop),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      surfaceInput: mix(surfaceInput, other.surfaceInput),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      inUse: mix(inUse, other.inUse),
      available: mix(available, other.available),
      maintenance: mix(maintenance, other.maintenance),
      missing: mix(missing, other.missing),
      live: mix(live, other.live),
      critical: mix(critical, other.critical),
      warning: mix(warning, other.warning),
      info: mix(info, other.info),
    );
  }
}

/// Atalho para a paleta do tema corrente.
///
/// O `!` é seguro porque os dois [ThemeData] do app registram a extensão; se
/// algum tema esquecer, quebra alto e na hora em vez de pintar a cor errada.
extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
