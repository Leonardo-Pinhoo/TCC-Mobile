// Gera os ícones de launcher do Android a partir do wordmark da Atlas.
//
// Rodar com:
//   flutter test tool/generate_launcher_icons.dart
//
// Usa o `flutter test` só para ter um binding com `dart:ui` disponível — assim
// a geração não precisa de pacote novo, de rede nem de ImageMagick/Python.
// O arquivo mora em tool/ (e não em test/) para ficar de fora do `flutter test`
// sem argumentos, que roda a suíte de verdade.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wordmark de origem: cinza claro→branco sobre preto chapado, sem alpha.
const String _sourcePath = 'tool/brand/atlas-wordmark.png';
const String _resPath = 'android/app/src/main/res';

/// Fundo do ícone. Igual ao preto do próprio wordmark, para que a camada de
/// frente e a de trás do adaptive icon não mostrem emenda.
const int _backgroundArgb = 0xFF000000;

/// Lado do `ic_launcher.png` legado em cada densidade.
const Map<String, int> _legacySizes = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Fração da largura do ícone legado ocupada pelo wordmark.
/// O ícone legado sangra até a borda e costuma levar só um arredondamento.
const double _legacyWidthFactor = 0.72;

/// Fração da largura ocupada pelo wordmark na camada de frente do adaptive
/// icon. A arte tem 108dp e só o círculo central de 66dp é garantido em todas
/// as máscaras. Uma forma de w×h inscrita nesse círculo obedece
/// √(w²+h²) ≤ 66; com a proporção ~3,1:1 do wordmark isso dá w ≤ 0,58×108.
/// 0,57 deixa uma folga pequena e fica no limite do que é sempre visível.
const double _adaptiveWidthFactor = 0.57;

/// Lado da arte do adaptive icon: 108dp na densidade correspondente.
int _adaptiveSize(int legacySize) => (legacySize * 108 / 48).round();

void main() {
  testWidgets('gera os ícones de launcher', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final Directory projectRoot = Directory.current;
      final File source = File('${projectRoot.path}/$_sourcePath');
      if (!source.existsSync()) {
        fail('Wordmark não encontrado em $_sourcePath');
      }

      final ui.Image mark = await _loadMarkWithAlpha(source);
      final Rect box = await _opaqueBounds(mark);
      stdout.writeln(
        'Wordmark: ${box.width.round()}x${box.height.round()} px '
        '(proporção ${(box.width / box.height).toStringAsFixed(2)}:1)',
      );

      for (final MapEntry<String, int> entry in _legacySizes.entries) {
        final String density = entry.key;
        final int legacy = entry.value;
        final int adaptive = _adaptiveSize(legacy);

        await _writePng(
          '$_resPath/mipmap-$density/ic_launcher.png',
          await _compose(
            mark: mark,
            source: box,
            canvasSize: legacy,
            widthFactor: _legacyWidthFactor,
            background: const Color(_backgroundArgb),
          ),
        );

        await _writePng(
          '$_resPath/mipmap-$density/ic_launcher_foreground.png',
          await _compose(
            mark: mark,
            source: box,
            canvasSize: adaptive,
            widthFactor: _adaptiveWidthFactor,
            background: null,
          ),
        );

        stdout.writeln('  $density: ${legacy}px legado + ${adaptive}px frente');
      }

      _writeAdaptiveXml();
      stdout.writeln('Pronto.');
    });
  });
}

/// Decodifica o wordmark e transforma o preto do fundo em transparência.
///
/// A arte é cinza sobre preto, então a luminância serve direto de alpha. Como
/// o buffer do Flutter é RGBA pré-multiplicado, um pixel cinza (v,v,v) vira
/// (v,v,v,v) — que é branco com alpha v, e compõe sobre preto exatamente com o
/// mesmo valor de antes. A troca é invisível no fundo preto e ainda dá bordas
/// limpas quando o launcher recorta a máscara.
Future<ui.Image> _loadMarkWithAlpha(File source) async {
  final Uint8List encoded = await source.readAsBytes();
  final ui.Codec codec = await ui.instantiateImageCodec(encoded);
  final ui.FrameInfo frame = await codec.getNextFrame();
  final ui.Image decoded = frame.image;

  final ByteData? raw =
      await decoded.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (raw == null) fail('Não consegui ler os pixels do wordmark.');
  final Uint8List pixels = raw.buffer.asUint8List();

  for (int i = 0; i < pixels.length; i += 4) {
    final int r = pixels[i];
    final int g = pixels[i + 1];
    final int b = pixels[i + 2];
    pixels[i + 3] = r > g ? (r > b ? r : b) : (g > b ? g : b);
  }

  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    decoded.width,
    decoded.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  final ui.Image result = await completer.future;
  decoded.dispose();
  return result;
}

/// Retângulo que encosta nos pixels visíveis, para o enquadramento não herdar
/// a margem vazia do arquivo de origem.
Future<Rect> _opaqueBounds(ui.Image image) async {
  final ByteData? raw =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (raw == null) fail('Não consegui medir o wordmark.');
  final Uint8List pixels = raw.buffer.asUint8List();

  const int threshold = 12;
  int minX = image.width, maxX = -1, minY = image.height, maxY = -1;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (pixels[(y * image.width + x) * 4 + 3] <= threshold) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < 0) fail('O wordmark parece estar inteiro transparente.');
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}

/// Desenha o wordmark centrado num quadrado de [canvasSize].
Future<ui.Image> _compose({
  required ui.Image mark,
  required Rect source,
  required int canvasSize,
  required double widthFactor,
  required Color? background,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final double side = canvasSize.toDouble();

  if (background != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()..color = background,
    );
  }

  final double targetWidth = side * widthFactor;
  final double targetHeight = targetWidth * source.height / source.width;
  canvas.drawImageRect(
    mark,
    source,
    Rect.fromLTWH(
      (side - targetWidth) / 2,
      (side - targetHeight) / 2,
      targetWidth,
      targetHeight,
    ),
    Paint()..filterQuality = FilterQuality.high,
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(canvasSize, canvasSize);
  picture.dispose();
  return image;
}

Future<void> _writePng(String relativePath, ui.Image image) async {
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) fail('Falhei ao codificar $relativePath');
  final File file = File('${Directory.current.path}/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png.buffer.asUint8List());
  image.dispose();
}

/// Declara o adaptive icon (Android 8+) e a cor de fundo dele.
void _writeAdaptiveXml() {
  File('${Directory.current.path}/$_resPath/mipmap-anydpi-v26/ic_launcher.xml')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''');

  File('${Directory.current.path}/$_resPath/values/ic_launcher_background.xml')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#000000</color>
</resources>
''');
}
