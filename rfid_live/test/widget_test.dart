import 'dart:math';
import 'dart:ui' show Tristate;

import 'package:rfid_live/app.dart';
import 'package:rfid_live/data/repositories/auth_repository.dart';
import 'package:rfid_live/data/repositories/plant_repository.dart';
import 'package:rfid_live/features/inventory/inventory_page.dart';
import 'package:rfid_live/state/auth_controller.dart';
import 'package:rfid_live/state/plant_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sobe o app com o simulador desligado — telas com animação infinita
/// ("ao vivo") nunca ficam estáveis para `pumpAndSettle`.
Future<void> pumpApp(WidgetTester tester, {bool authenticated = false}) async {
  // Superfície equivalente a um celular moderno (430x932 lógicos).
  tester.view.physicalSize = const Size(860, 1864);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final AuthController auth = AuthController();
  await auth.bootstrap();
  if (authenticated) {
    await auth.signIn(
      email: AuthRepository.demoEmail,
      password: AuthRepository.demoPassword,
    );
  }

  await tester.pumpWidget(
    RfidLiveApp(
      authController: auth,
      plantController: PlantController(
        repository: PlantRepository(random: Random(7)),
        autoStart: false,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

/// Restringe a busca à aba visível — o IndexedStack mantém as outras abas
/// construídas, então textos repetidos apareceriam em mais de uma tela.
Finder inInventory(Finder finder) =>
    find.descendant(of: find.byType(InventoryPage), matching: finder);

/// Descarta a árvore para que timers e animações sejam cancelados.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tela de login', () {
    testWidgets('exibe marca, status das antenas e ações', (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.text('RFID LIVE'), findsOneWidget);
      expect(find.text('Rastreamento de Ferramentas'), findsOneWidget);
      expect(find.text('5 antenas online · API conectada'), findsOneWidget);
      expect(find.text('Entrar na plataforma'), findsOneWidget);
      expect(find.text('Acesso restrito — Sistema Industrial v1.0.0'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Criar nova conta'), findsOneWidget);
      expect(find.text('TCC RFID 2025 · Sistema Inteligente Industrial'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('valida os campos antes de autenticar', (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Informe o e-mail corporativo'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('recusa credenciais inválidas', (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'desconhecido@empresa.com.br',
      );
      await tester.enterText(find.byType(TextFormField).last, 'senha123');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Usuário não encontrado'), findsOneWidget);
      expect(find.text('Painel Geral'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('acesso de demonstração abre o painel', (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.ensureVisible(find.text('Preencher acesso de demonstração'));
      await tester.pump();
      await tester.tap(find.text('Preencher acesso de demonstração'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Painel Geral'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('Painel Geral', () {
    testWidgets('mostra os indicadores da planta', (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);

      expect(find.text('Painel Geral'), findsOneWidget);
      expect(find.text('TOTAL RASTREADAS'), findsOneWidget);
      expect(find.text('EM USO AGORA'), findsOneWidget);
      expect(find.text('DISPONÍVEIS'), findsOneWidget);
      expect(find.text('NÃO LOCALIZADAS'), findsOneWidget);
      expect(find.text('DISTRIBUIÇÃO DE STATUS'), findsOneWidget);
      expect(find.text('INDICADORES OPERACIONAIS'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pump();
      expect(find.text('ÚLTIMAS MOVIMENTAÇÕES'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('lista os alertas da operação', (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pump();

      expect(find.text('ALERTAS ATIVOS'), findsOneWidget);
      expect(find.text('Ferramenta não localizada'), findsWidgets);

      await disposeApp(tester);
    });
  });

  group('Navegação entre abas', () {
    testWidgets('abre mapa, inventário, alertas e histórico', (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);

      await tester.tap(find.text('MAPA'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mapa da Planta'), findsOneWidget);
      expect(find.text('PLANTA INDUSTRIAL — TEMPO REAL'), findsOneWidget);
      expect(find.text('Toque em uma zona para ver detalhes'), findsOneWidget);

      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Inventário'), findsOneWidget);
      expect(find.text('Buscar ferramenta, ID ou tag...'), findsOneWidget);

      await tester.tap(find.text('ALERTAS'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Alertas'), findsOneWidget);

      await tester.tap(find.text('HISTÓRICO'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Histórico'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('Inventário', () {
    testWidgets('busca filtra as ferramentas listadas', (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('6 de 6 ferramentas'), findsOneWidget);

      await tester.enterText(inInventory(find.byType(TextField)).first, 'multímetro');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 de 6 ferramentas'), findsOneWidget);
      expect(inInventory(find.text('Multímetro Digital Fluke')), findsOneWidget);
      expect(inInventory(find.text('Chave de Impacto 1/2"')), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('busca sem resultado mostra estado vazio', (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(inInventory(find.byType(TextField)).first, 'furadeira xyz');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nenhuma ferramenta encontrada'), findsOneWidget);

      await tester.tap(find.text('Limpar filtros'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('6 de 6 ferramentas'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('filtro de status seleciona apenas um grupo', (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(inInventory(find.text('Manutenção')).first);
      await tester.pump();
      await tester.tap(inInventory(find.text('Manutenção')).first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 de 6 ferramentas'), findsOneWidget);
      expect(inInventory(find.text('Alicate Universal 8"')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('abre a ficha da ferramenta e registra manutenção',
        (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(inInventory(find.text('Chave de Impacto 1/2"')).first);
      // Um frame para construir a rota e outro para concluir a transição.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('FER-001'), findsWidgets);
      expect(find.text('FICHA TÉCNICA'), findsOneWidget);
      expect(find.text('Manutenção'), findsOneWidget);

      await tester.tap(find.text('Manutenção'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Concluir'), findsOneWidget);
      expect(find.textContaining('enviada para a manutenção'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('arrasta para o lado troca de ferramenta dentro da ficha',
        (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      // Ordenação padrão é "leitura mais recente": FER-001 é a primeira.
      await tester.tap(inInventory(find.text('Chave de Impacto 1/2"')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('FER-001'), findsWidgets);
      expect(find.text('1 de 6'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('FER-002'), findsWidgets);
      expect(find.text('Parafusadeira Bosch GSR'), findsWidgets);
      expect(find.text('2 de 6'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('cadastro recusa um EPC já vinculado a outra ferramenta',
        (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Cadastrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('CADASTRAR FERRAMENTA'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex.: Chave de Fenda Isolada 6mm'),
        'Chave duplicada',
      );
      // EPC já em uso pela FER-001 do inventário inicial.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E2:00:1A:B3'),
        'E2:00:1A:B3',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '0,00'),
        '150',
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Cadastrar ferramenta'));
      await tester.pump();
      await tester.tap(find.text('Cadastrar ferramenta'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('EPC já vinculado a FER-001'), findsOneWidget);
      // A folha continua aberta e nada foi gravado no inventário.
      expect(find.text('CADASTRAR FERRAMENTA'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('cadastro recusa um EPC fora do formato hexadecimal',
        (WidgetTester tester) async {
      await pumpApp(tester, authenticated: true);
      await tester.tap(find.text('INVENTÁRIO'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Cadastrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex.: Chave de Fenda Isolada 6mm'),
        'Etiqueta torta',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E2:00:1A:B3'),
        'E2:00:1A:G6',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '0,00'),
        '150',
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Cadastrar ferramenta'));
      await tester.pump();
      await tester.tap(find.text('Cadastrar ferramenta'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Formato inválido'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('Acessibilidade', () {
    testWidgets('indicadores e abas expõem rótulos para o leitor de tela',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, authenticated: true);

      // KPIs do painel: rótulo, número e legenda lidos como uma frase só.
      expect(
        find.bySemanticsLabel(RegExp(r'^Total rastreadas: 6\.')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Em uso agora: 2\.')),
        findsOneWidget,
      );

      // Distribuição de status e anel de BI — o Flutter mescla estes nós no
      // cartão que os contém, então a busca é por trecho.
      expect(
        find.bySemanticsLabel(RegExp('Em uso: 2 de 6 ferramentas')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Utilização: 33%')), findsWidgets);

      // Aba ativa é anunciada como selecionada.
      final SemanticsNode painel = tester.getSemantics(
        find.bySemanticsLabel('Painel').first,
      );
      // isSelected é tri-estado: "não aplicável" e "não selecionado" diferem.
      expect(painel.flagsCollection.isSelected, Tristate.isTrue);
      expect(painel.flagsCollection.isButton, isTrue);

      // A aba de alertas anuncia a quantidade, não um número solto.
      expect(
        find.bySemanticsLabel(RegExp(r'^Alertas, \d+ ativos$')),
        findsOneWidget,
      );

      // O botão de atualizar é um InkWell: sem rótulo não seria anunciado.
      expect(
        find.bySemanticsLabel('Atualizar leituras das antenas'),
        findsOneWidget,
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
