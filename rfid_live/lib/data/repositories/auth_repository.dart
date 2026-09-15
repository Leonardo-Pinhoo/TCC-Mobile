import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Autenticação local (offline-first) usada pela demonstração do sistema.
///
/// As senhas nunca são gravadas em texto puro: guarda-se apenas o hash
/// SHA-256 combinado com um salt aleatório por usuário.
class AuthRepository {
  static const String _usersKey = 'rfid_live_users';
  static const String _sessionKey = 'rfid_live_session';

  static const String demoEmail = 'admin@rfidlive.com.br';
  static const String demoPassword = '123456';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, dynamic>> _readUsers() async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeUsers(Map<String, dynamic> users) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  String _newSalt() {
    final Random random = Random.secure();
    final List<int> bytes =
        List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _normalize(String email) => email.trim().toLowerCase();

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final String key = _normalize(email);
    if (key == demoEmail && password == demoPassword) {
      const AppUser user = AppUser(
        name: 'Supervisor de Ferramentaria',
        email: demoEmail,
        role: 'Administrador',
      );
      await _saveSession(user);
      return user;
    }

    final Map<String, dynamic> users = await _readUsers();
    final Object? record = users[key];
    if (record is! Map<String, dynamic>) {
      throw AuthException('Usuário não encontrado. Verifique o e-mail.');
    }
    final String salt = record['salt'] as String;
    if (_hash(password, salt) != record['hash']) {
      throw AuthException('Senha incorreta. Tente novamente.');
    }
    final AppUser user = AppUser.fromJson(record);
    await _saveSession(user);
    return user;
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'Operação',
  }) async {
    final String key = _normalize(email);
    if (key == demoEmail) {
      throw AuthException('Este e-mail já está cadastrado.');
    }
    final Map<String, dynamic> users = await _readUsers();
    if (users.containsKey(key)) {
      throw AuthException('Este e-mail já está cadastrado.');
    }
    final String salt = _newSalt();
    final AppUser user = AppUser(name: name.trim(), email: key, role: role);
    users[key] = <String, dynamic>{
      ...user.toJson(),
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await _writeUsers(users);
    await _saveSession(user);
    return user;
  }

  Future<void> _saveSession(AppUser user) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<AppUser?> restoreSession() async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_sessionKey);
  }
}
