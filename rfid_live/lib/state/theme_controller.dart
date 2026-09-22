import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a escolha de tema do usuário: seguir o sistema, claro ou escuro.
///
/// Segue o mesmo padrão de persistência do [PlantController]: preferência
/// simples em [SharedPreferences], lida na partida do app.
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'rfid_live_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> loadPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _mode = _decode(prefs.getString(_prefKey));
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  /// Valor ausente ou desconhecido volta a seguir o sistema. Uma preferência
  /// corrompida não deve impedir o app de abrir.
  static ThemeMode _decode(String? raw) {
    if (raw == null) return ThemeMode.system;
    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return ThemeMode.system;
  }
}
