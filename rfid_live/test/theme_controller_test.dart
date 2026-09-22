import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfid_live/state/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('começa seguindo o sistema', () {
    expect(ThemeController().mode, ThemeMode.system);
  });

  test('sem preferência gravada continua seguindo o sistema', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ThemeController controller = ThemeController();
    await controller.loadPreference();
    expect(controller.mode, ThemeMode.system);
  });

  test('setMode grava a escolha e avisa os ouvintes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ThemeController controller = ThemeController();
    int avisos = 0;
    controller.addListener(() => avisos++);

    await controller.setMode(ThemeMode.light);

    expect(controller.mode, ThemeMode.light);
    expect(avisos, 1);

    final ThemeController outro = ThemeController();
    await outro.loadPreference();
    expect(outro.mode, ThemeMode.light,
        reason: 'a escolha deveria sobreviver ao reinício do app');
  });

  test('preferência corrompida volta para o sistema em vez de estourar',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'rfid_live_theme_mode': 'roxo',
    });
    final ThemeController controller = ThemeController();
    await controller.loadPreference();
    expect(controller.mode, ThemeMode.system);
  });

  test('os três modos sobrevivem a uma ida e volta', () async {
    for (final ThemeMode mode in ThemeMode.values) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ThemeController gravador = ThemeController();
      await gravador.setMode(mode);

      final ThemeController leitor = ThemeController();
      await leitor.loadPreference();
      expect(leitor.mode, mode);
    }
  });
}
