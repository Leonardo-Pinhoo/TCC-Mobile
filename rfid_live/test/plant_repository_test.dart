import 'dart:math';

import 'package:rfid_live/data/models/movement.dart';
import 'package:rfid_live/data/models/plant_alert.dart';
import 'package:rfid_live/data/models/tool.dart';
import 'package:rfid_live/data/repositories/plant_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlantRepository repository;

  setUp(() {
    repository = PlantRepository(random: Random(42));
  });

  group('carga inicial', () {
    test('reproduz o inventário apresentado no painel', () {
      expect(repository.tools, hasLength(6));
      expect(repository.countByStatus(ToolStatus.inUse), 2);
      expect(repository.countByStatus(ToolStatus.available), 2);
      expect(repository.countByStatus(ToolStatus.maintenance), 1);
      expect(repository.countByStatus(ToolStatus.missing), 1);
      expect(repository.activeAlerts, hasLength(3));
      expect(repository.antennas, hasLength(5));
    });

    test('cada zona da planta tem exatamente uma ferramenta', () {
      for (final String zoneId in <String>[
        'ZN-001',
        'ZN-002',
        'ZN-003',
        'ZN-004',
        'ZN-005',
      ]) {
        expect(repository.toolsInZone(zoneId), hasLength(1), reason: zoneId);
      }
      expect(repository.unlocatedTools, hasLength(1));
    });

    test('indicadores derivam do inventário', () {
      final PlantStats stats = repository.stats;
      expect(stats.total, 6);
      expect(stats.utilizationRate, closeTo(2 / 6, 0.001));
      expect(stats.visibilityRate, closeTo(5 / 6, 0.001));
      expect(stats.overdueMaintenance, 1);
      expect(stats.assetValue, greaterThan(stats.trackedAssetValue));
    });
  });

  group('busca', () {
    test('encontra por nome, código e etiqueta', () {
      expect(repository.search(query: 'chave'), hasLength(1));
      expect(repository.search(query: 'FER-004'), hasLength(1));
      expect(repository.search(query: 'e2:00:2c'), hasLength(1));
      expect(repository.search(query: 'linha a'), hasLength(1));
    });

    test('combina texto e filtro de status', () {
      expect(
        repository.search(query: 'a', status: ToolStatus.missing),
        hasLength(1),
      );
      expect(
        repository.search(query: 'zzz', status: ToolStatus.inUse),
        isEmpty,
      );
    });
  });

  group('movimentações', () {
    test('transferir para uma linha coloca a ferramenta em uso', () {
      final Movement movement = repository.registerMovement(
        toolId: 'FER-002',
        toZoneId: 'ZN-001',
        user: 'Carlos M.',
      );

      final Tool tool = repository.toolById('FER-002')!;
      expect(tool.zoneId, 'ZN-001');
      expect(tool.status, ToolStatus.inUse);
      expect(tool.holder, 'Carlos M.');
      expect(movement.fromZoneId, 'ZN-005');
      expect(repository.movements.first.id, movement.id);
    });

    test('devolver ao almoxarifado libera a ferramenta', () {
      repository.registerMovement(
        toolId: 'FER-001',
        toZoneId: 'ZN-005',
        user: 'Carlos M.',
      );

      final Tool tool = repository.toolById('FER-001')!;
      expect(tool.status, ToolStatus.available);
      expect(tool.holder, isNull);
      expect(repository.movements.first.type, MovementType.checkin);
    });

    test('reencontrar uma ferramenta perdida resolve o alerta', () {
      expect(
        repository.activeAlerts.any((PlantAlert a) => a.toolId == 'FER-004'),
        isTrue,
      );

      repository.markAsFound(
        toolId: 'FER-004',
        zoneId: 'ZN-003',
        user: 'Julia F.',
      );

      expect(repository.toolById('FER-004')!.status, ToolStatus.inUse);
      expect(
        repository.activeAlerts.any((PlantAlert a) => a.toolId == 'FER-004'),
        isFalse,
      );
    });

    test('registra o rastro completo de uma ferramenta', () {
      repository.registerMovement(
        toolId: 'FER-002',
        toZoneId: 'ZN-001',
        user: 'Ana R.',
      );
      repository.registerMovement(
        toolId: 'FER-002',
        toZoneId: 'ZN-005',
        user: 'Ana R.',
      );

      expect(repository.movementsOfTool('FER-002').length, greaterThanOrEqualTo(3));
    });
  });

  group('manutenção', () {
    test('enviar e concluir devolve a ferramenta disponível', () {
      repository.sendToMaintenance(toolId: 'FER-001', user: 'Ana R.');
      expect(repository.toolById('FER-001')!.status, ToolStatus.maintenance);

      repository.finishMaintenance(toolId: 'FER-001', user: 'Ana R.');
      final Tool tool = repository.toolById('FER-001')!;
      expect(tool.status, ToolStatus.available);
      expect(tool.zoneId, 'ZN-005');
      expect(tool.maintenanceOverdue, isFalse);
    });

    test('concluir manutenção vencida resolve o alerta correspondente', () {
      repository.finishMaintenance(toolId: 'FER-003', user: 'Ana R.');
      expect(
        repository.activeAlerts
            .any((PlantAlert a) => a.kind == AlertKind.maintenanceOverdue),
        isFalse,
      );
    });
  });

  group('localização por antena', () {
    test('devolve leitura para ferramenta dentro da cobertura', () {
      final TagReading? reading = repository.locate('FER-001');
      expect(reading, isNotNull);
      expect(reading!.antennaId, 'ANT-01');
      expect(repository.readings.first.toolId, 'FER-001');
    });

    test('devolve nulo para ferramenta fora da cobertura', () {
      expect(repository.locate('FER-004'), isNull);
    });
  });

  group('cadastro e alertas', () {
    test('cadastrar gera código sequencial e movimento de registro', () {
      final Tool tool = repository.addTool(
        name: 'Chave de Fenda Isolada',
        tag: 'E2:00:9F:11',
        zoneId: 'ZN-005',
        category: 'Manual',
        assetValue: 180,
        criticality: 'Baixa',
        user: 'Pedro S.',
      );

      expect(tool.id, 'FER-007');
      expect(tool.status, ToolStatus.available);
      expect(repository.tools, hasLength(7));
      expect(repository.movements.first.type, MovementType.register);
    });

    test('cadastrar normaliza o EPC para maiúsculas', () {
      final Tool tool = repository.addTool(
        name: 'Chave Allen 5mm',
        tag: 'e2:00:aa:0f',
        zoneId: 'ZN-005',
        category: 'Manual',
        assetValue: 90,
        criticality: 'Baixa',
        user: 'Ana R.',
      );

      expect(tool.tag, 'E2:00:AA:0F');
      expect(repository.toolByTag('e2:00:aa:0f')?.id, tool.id);
    });

    test('o EPC é único: não permite duas etiquetas com o mesmo código', () {
      final String existing = repository.tools.first.tag;

      expect(
        () => repository.addTool(
          name: 'Cópia indevida',
          tag: existing,
          zoneId: 'ZN-005',
          category: 'Manual',
          assetValue: 100,
          criticality: 'Baixa',
          user: 'Ana R.',
        ),
        throwsA(isA<PlantException>()),
      );
      expect(repository.tools, hasLength(6));
    });

    test('EPC fora do formato das antenas é recusado', () {
      for (final String invalid in <String>[
        'ABC',
        'E2:00:1A',
        'E2:00:1A:G6',
        'E3:00:1A:B4',
      ]) {
        expect(
          () => repository.addTool(
            name: 'Etiqueta inválida',
            tag: invalid,
            zoneId: 'ZN-005',
            category: 'Manual',
            assetValue: 100,
            criticality: 'Baixa',
            user: 'Ana R.',
          ),
          throwsA(isA<PlantException>()),
          reason: invalid,
        );
      }
      expect(repository.tools, hasLength(6));
    });

    test('todo EPC do inventário inicial é hexadecimal válido', () {
      for (final Tool tool in repository.tools) {
        expect(
          PlantRepository.isValidEpc(tool.tag),
          isTrue,
          reason: '${tool.id} carrega o EPC ${tool.tag}',
        );
      }
    });

    test('o código patrimonial nunca é reaproveitado', () {
      final Tool first = repository.addTool(
        name: 'Ferramenta A',
        tag: 'E2:00:B1:01',
        zoneId: 'ZN-005',
        category: 'Manual',
        assetValue: 100,
        criticality: 'Baixa',
        user: 'Ana R.',
      );
      final Tool second = repository.addTool(
        name: 'Ferramenta B',
        tag: 'E2:00:B1:02',
        zoneId: 'ZN-005',
        category: 'Manual',
        assetValue: 100,
        criticality: 'Baixa',
        user: 'Ana R.',
      );

      expect(first.id, 'FER-007');
      expect(second.id, 'FER-008');
      expect(
        repository.tools.map((Tool t) => t.id).toSet(),
        hasLength(repository.tools.length),
      );
    });

    test('resolver alertas remove-os da lista de ativos', () {
      final String id = repository.activeAlerts.first.id;
      repository.resolveAlert(id);
      expect(repository.activeAlerts.any((PlantAlert a) => a.id == id), isFalse);

      repository.resolveAllAlerts();
      expect(repository.activeAlerts, isEmpty);
      expect(repository.alerts, isNotEmpty);
    });
  });

  group('simulação em tempo real', () {
    test('mantém o estado consistente após muitos ciclos', () {
      for (int i = 0; i < 500; i++) {
        repository.tick();
      }

      expect(repository.tools, hasLength(6));
      expect(repository.countByStatus(ToolStatus.missing), lessThanOrEqualTo(2));
      expect(repository.movements.length, lessThanOrEqualTo(250));
      expect(repository.readings.length, lessThanOrEqualTo(60));

      for (final Tool tool in repository.tools) {
        if (tool.status == ToolStatus.missing) {
          expect(tool.zoneId, isNull);
        } else {
          expect(tool.zoneId, isNotNull);
        }
      }

      final PlantStats stats = repository.stats;
      expect(
        stats.inUse + stats.available + stats.maintenance + stats.missing,
        stats.total,
      );
    });

    test('agrupa movimentações por hora dentro de 24 posições', () {
      for (int i = 0; i < 50; i++) {
        repository.tick();
      }
      final List<int> buckets = repository.movementsByHour();
      expect(buckets, hasLength(24));
      expect(buckets.every((int value) => value >= 0), isTrue);
    });

    test('ranking de movimentação respeita o limite pedido', () {
      final List<MapEntry<Tool, int>> ranking = repository.topMovedTools(limit: 3);
      expect(ranking.length, lessThanOrEqualTo(3));
      for (int i = 1; i < ranking.length; i++) {
        expect(ranking[i - 1].value, greaterThanOrEqualTo(ranking[i].value));
      }
    });
  });
}
