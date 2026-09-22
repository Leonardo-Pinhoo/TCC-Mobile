import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rfid_live/core/theme/app_palette.dart';

/// Luminância relativa segundo a WCAG 2.1.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// Razão de contraste entre duas cores opacas.
double contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const Map<String, AppPalette> palettes = <String, AppPalette>{
    'escuro': AppPalette.dark,
    'claro': AppPalette.light,
  };

  group('contraste mínimo', () {
    // `textMuted` fica de fora de propósito. Ele já está em 2,96:1 no tema
    // escuro que existia antes desta mudança — é texto terciário decorativo,
    // e corrigi-lo tem impacto visual em toda tela. Está registrado como
    // não-objetivo em docs/superpowers/specs/2026-09-22-tema-claro-escuro-design.md
    palettes.forEach((String name, AppPalette palette) {
      Map<String, Color> aferidos() => <String, Color>{
            'textPrimary': palette.textPrimary,
            'textSecondary': palette.textSecondary,
            'inUse': palette.inUse,
            'available': palette.available,
            'maintenance': palette.maintenance,
            'missing': palette.missing,
            'live': palette.live,
            'critical': palette.critical,
            'warning': palette.warning,
            'info': palette.info,
          };

      aferidos().forEach((String token, Color color) {
        test('tema $name: $token atinge 4.5:1 sobre o fundo', () {
          final double ratio = contrast(color, palette.background);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$token no tema $name está em '
                '${ratio.toStringAsFixed(2)}:1, abaixo do mínimo AA de 4.5:1',
          );
        });
      });
    });
  });

  group('cobertura da paleta', () {
    // Pega o erro de copiar a paleta escura e esquecer de inverter um token.
    // Não enumera os campos por reflexão (indisponível no Flutter), então
    // acrescentar um campo novo exige acrescentá-lo aqui também.
    test('todo token muda entre os dois temas', () {
      final Map<String, Color> dark = <String, Color>{
        'background': AppPalette.dark.background,
        'backgroundTop': AppPalette.dark.backgroundTop,
        'surface': AppPalette.dark.surface,
        'surfaceAlt': AppPalette.dark.surfaceAlt,
        'surfaceInput': AppPalette.dark.surfaceInput,
        'border': AppPalette.dark.border,
        'borderStrong': AppPalette.dark.borderStrong,
        'primary': AppPalette.dark.primary,
        'onPrimary': AppPalette.dark.onPrimary,
        'textPrimary': AppPalette.dark.textPrimary,
        'textSecondary': AppPalette.dark.textSecondary,
        'textMuted': AppPalette.dark.textMuted,
        'inUse': AppPalette.dark.inUse,
        'available': AppPalette.dark.available,
        'maintenance': AppPalette.dark.maintenance,
        'missing': AppPalette.dark.missing,
        'live': AppPalette.dark.live,
        'critical': AppPalette.dark.critical,
        'warning': AppPalette.dark.warning,
        'info': AppPalette.dark.info,
      };
      final Map<String, Color> light = <String, Color>{
        'background': AppPalette.light.background,
        'backgroundTop': AppPalette.light.backgroundTop,
        'surface': AppPalette.light.surface,
        'surfaceAlt': AppPalette.light.surfaceAlt,
        'surfaceInput': AppPalette.light.surfaceInput,
        'border': AppPalette.light.border,
        'borderStrong': AppPalette.light.borderStrong,
        'primary': AppPalette.light.primary,
        'onPrimary': AppPalette.light.onPrimary,
        'textPrimary': AppPalette.light.textPrimary,
        'textSecondary': AppPalette.light.textSecondary,
        'textMuted': AppPalette.light.textMuted,
        'inUse': AppPalette.light.inUse,
        'available': AppPalette.light.available,
        'maintenance': AppPalette.light.maintenance,
        'missing': AppPalette.light.missing,
        'live': AppPalette.light.live,
        'critical': AppPalette.light.critical,
        'warning': AppPalette.light.warning,
        'info': AppPalette.light.info,
      };

      for (final String token in dark.keys) {
        expect(
          light[token],
          isNot(equals(dark[token])),
          reason: '$token tem o mesmo valor nos dois temas',
        );
      }
    });
  });

  group('lerp', () {
    test('em t=0 devolve a paleta de origem e em t=1 a de destino', () {
      expect(
        AppPalette.dark.lerp(AppPalette.light, 0).background,
        AppPalette.dark.background,
      );
      expect(
        AppPalette.dark.lerp(AppPalette.light, 1).background,
        AppPalette.light.background,
      );
    });
  });
}
