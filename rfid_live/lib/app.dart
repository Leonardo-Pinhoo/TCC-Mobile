import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/shell/home_shell.dart';
import 'state/auth_controller.dart';
import 'state/plant_controller.dart';

class RfidLiveApp extends StatelessWidget {
  const RfidLiveApp({super.key, this.authController, this.plantController});

  /// Controladores injetáveis — usados pelos testes para desligar o
  /// simulador em tempo real e isolar cada cenário.
  final AuthController? authController;
  final PlantController? plantController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => authController ?? (AuthController()..bootstrap()),
        ),
        ChangeNotifierProvider<PlantController>(
          create: (_) => plantController ?? (PlantController()..loadPreferences()),
        ),
      ],
      child: MaterialApp(
        title: 'RFID LIVE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (BuildContext context, Widget? child) {
          // Impede que a fonte do sistema quebre o layout industrial denso.
          final MediaQueryData media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _AppGate(),
      ),
    );
  }
}

/// Decide entre splash, login e área autenticada.
class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final AuthStatus status =
        context.select<AuthController, AuthStatus>((AuthController c) => c.status);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (status) {
        AuthStatus.unknown => const _SplashScreen(),
        AuthStatus.unauthenticated => const LoginPage(),
        AuthStatus.authenticated => const HomeShell(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.sensors, size: 44, color: AppColors.primary),
            SizedBox(height: 18),
            Text(
              'RFID LIVE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
