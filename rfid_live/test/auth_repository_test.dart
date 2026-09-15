import 'package:dart_flutter/data/models/app_user.dart';
import 'package:dart_flutter/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = AuthRepository();
  });

  test('aceita o acesso de demonstração', () async {
    final AppUser user = await repository.signIn(
      email: AuthRepository.demoEmail,
      password: AuthRepository.demoPassword,
    );
    expect(user.role, 'Administrador');
    expect(await repository.restoreSession(), isNotNull);
  });

  test('e-mail é normalizado para minúsculas', () async {
    final AppUser user = await repository.signIn(
      email: '  ADMIN@RFIDLIVE.COM.BR ',
      password: AuthRepository.demoPassword,
    );
    expect(user.email, AuthRepository.demoEmail);
  });

  test('cadastro permite login posterior', () async {
    await repository.signUp(
      name: 'Carlos Mendes',
      email: 'carlos@empresa.com.br',
      password: 'senha123',
      role: 'Supervisão',
    );
    await repository.signOut();
    expect(await repository.restoreSession(), isNull);

    final AppUser user = await repository.signIn(
      email: 'carlos@empresa.com.br',
      password: 'senha123',
    );
    expect(user.name, 'Carlos Mendes');
    expect(user.role, 'Supervisão');
    expect(user.initials, 'CM');
  });

  test('senha incorreta é recusada', () async {
    await repository.signUp(
      name: 'Ana Rocha',
      email: 'ana@empresa.com.br',
      password: 'senha123',
    );
    expect(
      () => repository.signIn(email: 'ana@empresa.com.br', password: 'outra1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('usuário inexistente é recusado', () {
    expect(
      () => repository.signIn(email: 'ninguem@empresa.com.br', password: '123456'),
      throwsA(isA<AuthException>()),
    );
  });

  test('e-mail duplicado não pode ser cadastrado', () async {
    await repository.signUp(
      name: 'Ana Rocha',
      email: 'ana@empresa.com.br',
      password: 'senha123',
    );
    expect(
      () => repository.signUp(
        name: 'Outra Ana',
        email: 'ANA@empresa.com.br',
        password: 'senha456',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('a senha nunca é gravada em texto puro', () async {
    await repository.signUp(
      name: 'Pedro Silva',
      email: 'pedro@empresa.com.br',
      password: 'senhaSecreta',
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String stored = prefs.getString('rfid_live_users') ?? '';
    expect(stored, isNot(contains('senhaSecreta')));
    expect(stored, contains('hash'));
  });
}
