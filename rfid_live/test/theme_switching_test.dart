import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfid_live/app.dart';
import 'package:rfid_live/core/theme/app_palette.dart';
import 'package:rfid_live/data/repositories/auth_repository.dart';
import 'package:rfid_live/data/repositories/plant_repository.dart';
import 'package:rfid_live/state/auth_controller.dart';
import 'package:rfid_live/state/plant_controller.dart';
import 'package:rfid_live/state/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ThemeController> pumpAuthenticated(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.dark,
}) async {
  tester.view.physicalSize = const Size(860, 1864);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final AuthController auth = AuthController();
  await auth.bootstrap();
  await auth.signIn(
    email: AuthRepository.demoEmail,
    password: AuthRepository.demoPassword,
  );

  final ThemeController theme = ThemeController();
  await theme.setMode(mode);

  await tester.pumpWidget(
    RfidLiveApp(
      authController: auth,
      themeController: theme,
      plantController: PlantController(
        repository: PlantRepository(random: Random(7)),
        autoStart: false,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return theme;
}

/// A paleta que o app está de fato aplicando na tela.
AppPalette paletteOnScreen(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(Scaffold).first);
  return Theme.of(context).extension<AppPalette>()!;
}

Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no modo escuro a tela usa a paleta escura',
      (WidgetTester tester) async {
    await pumpAuthenticated(tester, mode: ThemeMode.dark);
    expect(paletteOnScreen(tester).background, AppPalette.dark.background);
    await disposeApp(tester);
  });

  testWidgets('no modo claro a tela usa a paleta clara',
      (WidgetTester tester) async {
    await pumpAuthenticated(tester, mode: ThemeMode.light);
    final AppPalette palette = paletteOnScreen(tester);
    expect(palette.background, AppPalette.light.background);
    expect(
      palette.maintenance,
      AppPalette.light.maintenance,
      reason: 'o status precisa usar o tom escurecido no fundo claro',
    );
    await disposeApp(tester);
  });

  testWidgets('trocar o modo repinta a tela sem reiniciar o app',
      (WidgetTester tester) async {
    final ThemeController theme =
        await pumpAuthenticated(tester, mode: ThemeMode.dark);
    expect(paletteOnScreen(tester).background, AppPalette.dark.background);

    await theme.setMode(ThemeMode.light);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(paletteOnScreen(tester).background, AppPalette.light.background);
    await disposeApp(tester);
  });

  testWidgets('o painel da conta oferece os três modos e aplica a escolha',
      (WidgetTester tester) async {
    final ThemeController theme =
        await pumpAuthenticated(tester, mode: ThemeMode.dark);

    await tester.tap(find.text('CONTA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('APARÊNCIA'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);

    await tester.tap(find.text('Claro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(theme.mode, ThemeMode.light);
    await disposeApp(tester);
  });
}
