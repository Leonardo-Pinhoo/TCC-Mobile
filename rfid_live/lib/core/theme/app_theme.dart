import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Estilos tipograficos reaproveitados nas telas.
///
/// Sao apenas tipografia: familia, tamanho, peso e espacamento. A cor vem do
/// tema — ou herdada do [TextTheme], quando o estilo usa a cor de texto
/// principal, ou por [AppTexts], quando usa uma cor secundaria.
class AppText {
  const AppText._();

  static const String mono = 'monospace';

  /// Fonte "display" usada nos títulos, como no site da Atlas.
  static const String display = 'Alata';

  /// Raio padrao das superficies (cartoes, campos, dialogos): o site e quase
  /// todo reto, com no maximo 4px de arredondamento.
  static const double radius = 4;

  /// Rotulo pequeno em caixa alta, usado acima dos valores nos cartoes
  /// (o "eyebrow" do site: caixa alta, espacamento largo e cinza medio).
  static const TextStyle label = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
  );

  static const TextStyle labelStrong = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
  );

  /// Texto dos botoes: pequeno e espacado como as pilulas do site.
  static const TextStyle button = TextStyle(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  static const TextStyle value = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  // Alata so existe no peso Regular: pesos maiores gerariam negrito
  // sintetico, por isso os titulos usam w400 como no site.
  static const TextStyle title = TextStyle(
    fontFamily: display,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: display,
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: display,
    fontSize: 30,
    height: 1.05,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
  );

  static const TextStyle codeMono = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    height: 1.3,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.35,
  );
}

/// Os estilos de [AppText] que nao usam a cor de texto principal, ja tingidos
/// com a paleta do tema corrente. Lidos via `context.texts`.
@immutable
class AppTexts {
  const AppTexts(this._palette);

  final AppPalette _palette;

  TextStyle get label => AppText.label.copyWith(color: _palette.textSecondary);
  TextStyle get labelStrong =>
      AppText.labelStrong.copyWith(color: _palette.textSecondary);
  TextStyle get code => AppText.codeMono.copyWith(color: _palette.textMuted);
  TextStyle get caption =>
      AppText.caption.copyWith(color: _palette.textSecondary);
}

extension AppTextsContext on BuildContext {
  AppTexts get texts => AppTexts(colors);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get dark =>
      _build(AppPalette.dark, Brightness.dark);

  static ThemeData get light =>
      _build(AppPalette.light, Brightness.light);

  /// Icones da barra de status e da barra de navegacao do sistema.
  ///
  /// Precisa acompanhar o tema: icones claros sobre o escuro, escuros sobre o
  /// claro. Entra pelo [AppBarTheme] em vez de uma chamada solta a
  /// `SystemChrome` justamente para trocar junto com o tema.
  static SystemUiOverlayStyle overlayStyleFor(
    AppPalette palette,
    Brightness brightness,
  ) {
    final bool isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: palette.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  /// Fabrica unica dos dois temas.
  ///
  /// Dois [ThemeData] escritos a mao divergiriam na primeira manutencao —
  /// alguem ajusta o raio de um botao num e esquece o outro. Aqui a unica
  /// diferenca entre claro e escuro e a paleta.
  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = (isDark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
        .copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.available,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      error: palette.missing,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      fontFamily: 'Inter',
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme().apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
        fontFamily: 'Inter',
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppText.radius),
          side: BorderSide(color: palette.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyleFor(palette, brightness),
        titleTextStyle: AppText.title.copyWith(color: palette.textPrimary),
        iconTheme: IconThemeData(color: palette.textSecondary),
      ),
      // Campos como no formulario do site: sem caixa, so uma linha inferior
      // que fica com a cor de acento ao receber foco.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(
          color: palette.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w300,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        border: _inputBorder(palette.border),
        enabledBorder: _inputBorder(palette.border),
        focusedBorder: _inputBorder(palette.primary),
        errorBorder: _inputBorder(palette.missing),
        focusedErrorBorder: _inputBorder(palette.missing),
        errorStyle: TextStyle(color: palette.missing, fontSize: 11),
      ),
      // Botoes em pilula como no site: o principal usa o acento com texto
      // contrastante, o secundario ("ghost") e transparente com borda sutil.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: palette.surfaceAlt,
          disabledForegroundColor: palette.textMuted,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppText.button,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: palette.borderStrong),
          textStyle: AppText.button,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          textStyle: AppText.button.copyWith(fontSize: 12),
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? palette.primary
                : palette.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? palette.onPrimary
                : palette.textSecondary,
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: palette.border),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: palette.primary,
        side: BorderSide(color: palette.border),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceAlt,
        contentTextStyle: TextStyle(color: palette.textPrimary, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppText.radius),
          side: BorderSide(color: palette.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppText.radius),
          side: BorderSide(color: palette.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceAlt,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          palette.borderStrong.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  static UnderlineInputBorder _inputBorder(Color color) => UnderlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: color),
      );
}
