import 'models/antenna.dart';
import 'models/movement.dart';
import 'models/plant_alert.dart';
import 'models/tool.dart';

/// Base de dados de demonstração do sistema RFID.
///
/// Os horários são gerados em relação ao momento de abertura do app para que a
/// planta sempre pareça "ao vivo", independentemente de quando for executada.
class SeedData {
  const SeedData._();

  static List<Tool> tools(DateTime now) => <Tool>[
        Tool(
          id: 'FER-001',
          name: 'Chave de Impacto 1/2"',
          tag: 'E2:00:1A:B3',
          status: ToolStatus.inUse,
          zoneId: 'ZN-001',
          holder: 'Carlos M.',
          lastRead: now.subtract(const Duration(minutes: 2)),
          nextMaintenance: now.add(const Duration(days: 5)),
          category: 'Pneumática',
          assetValue: 2450,
          criticality: 'Alta',
          usageMinutesToday: 96,
        ),
        Tool(
          id: 'FER-002',
          name: 'Parafusadeira Bosch GSR',
          tag: 'E2:00:2C:04',
          status: ToolStatus.available,
          zoneId: 'ZN-005',
          lastRead: now.subtract(const Duration(minutes: 5)),
          nextMaintenance: now.add(const Duration(days: 22)),
          category: 'Elétrica',
          assetValue: 1180,
          criticality: 'Média',
          usageMinutesToday: 34,
        ),
        Tool(
          id: 'FER-003',
          name: 'Alicate Universal 8"',
          tag: 'E2:00:3E:F5',
          status: ToolStatus.maintenance,
          zoneId: 'ZN-004',
          holder: 'Ana R.',
          lastRead: now.subtract(const Duration(hours: 1)),
          nextMaintenance: now.subtract(const Duration(days: 15)),
          category: 'Manual',
          assetValue: 320,
          criticality: 'Baixa',
          usageMinutesToday: 0,
        ),
        Tool(
          id: 'FER-004',
          name: 'Multímetro Digital Fluke',
          tag: 'E2:00:4A:C6',
          status: ToolStatus.missing,
          zoneId: null,
          lastRead: now.subtract(const Duration(hours: 6)),
          nextMaintenance: now.add(const Duration(days: 40)),
          category: 'Medição',
          assetValue: 3890,
          criticality: 'Alta',
          usageMinutesToday: 0,
        ),
        Tool(
          id: 'FER-005',
          name: 'Serra Circular Makita',
          tag: 'E2:00:5B:C7',
          status: ToolStatus.inUse,
          zoneId: 'ZN-003',
          holder: 'Julia F.',
          lastRead: now.subtract(const Duration(minutes: 12)),
          nextMaintenance: now.add(const Duration(days: 11)),
          category: 'Corte',
          assetValue: 2790,
          criticality: 'Alta',
          usageMinutesToday: 58,
        ),
        Tool(
          id: 'FER-006',
          name: 'Torquímetro 20-100 Nm',
          tag: 'E2:00:6D:18',
          status: ToolStatus.available,
          zoneId: 'ZN-002',
          lastRead: now.subtract(const Duration(minutes: 23)),
          nextMaintenance: now.add(const Duration(days: 3)),
          category: 'Medição',
          assetValue: 1650,
          criticality: 'Média',
          usageMinutesToday: 41,
        ),
      ];

  static List<Movement> movements(DateTime now) => <Movement>[
        Movement(
          id: 'MOV-006',
          toolId: 'FER-006',
          toolName: 'Torquímetro 20-100 Nm',
          fromZoneId: 'ZN-005',
          toZoneId: 'ZN-002',
          user: 'Pedro S.',
          type: MovementType.transfer,
          antennaId: 'ANT-02',
          timestamp: now.subtract(const Duration(minutes: 23)),
        ),
        Movement(
          id: 'MOV-005',
          toolId: 'FER-005',
          toolName: 'Serra Circular Makita',
          fromZoneId: 'ZN-001',
          toZoneId: 'ZN-003',
          user: 'Julia F.',
          type: MovementType.transfer,
          antennaId: 'ANT-03',
          timestamp: now.subtract(const Duration(minutes: 36)),
        ),
        Movement(
          id: 'MOV-004',
          toolId: 'FER-001',
          toolName: 'Chave de Impacto 1/2"',
          fromZoneId: 'ZN-005',
          toZoneId: 'ZN-001',
          user: 'Carlos M.',
          type: MovementType.checkout,
          antennaId: 'ANT-01',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 1)),
        ),
        Movement(
          id: 'MOV-003',
          toolId: 'FER-003',
          toolName: 'Alicate Universal 8"',
          fromZoneId: 'ZN-002',
          toZoneId: 'ZN-004',
          user: 'Ana R.',
          type: MovementType.maintenance,
          antennaId: 'ANT-04',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 12)),
        ),
        Movement(
          id: 'MOV-002',
          toolId: 'FER-002',
          toolName: 'Parafusadeira Bosch GSR',
          fromZoneId: 'ZN-001',
          toZoneId: 'ZN-005',
          user: 'Marcos L.',
          type: MovementType.checkin,
          antennaId: 'ANT-05',
          timestamp: now.subtract(const Duration(hours: 3, minutes: 5)),
        ),
        Movement(
          id: 'MOV-001',
          toolId: 'FER-004',
          toolName: 'Multímetro Digital Fluke',
          fromZoneId: 'ZN-005',
          toZoneId: 'ZN-003',
          user: 'Rafael T.',
          type: MovementType.checkout,
          antennaId: 'ANT-03',
          timestamp: now.subtract(const Duration(hours: 6, minutes: 20)),
        ),
      ];

  static List<PlantAlert> alerts(DateTime now) => <PlantAlert>[
        PlantAlert(
          id: 'ALT-001',
          kind: AlertKind.toolMissing,
          severity: AlertSeverity.critical,
          title: 'Ferramenta não localizada',
          description:
              'Multímetro Digital Fluke (FER-004) fora do alcance há 6h',
          toolId: 'FER-004',
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        PlantAlert(
          id: 'ALT-002',
          kind: AlertKind.maintenanceOverdue,
          severity: AlertSeverity.warning,
          title: 'Manutenção vencida',
          description:
              'Alicate Universal 8" (FER-003) — manutenção atrasada 15 dias',
          toolId: 'FER-003',
          createdAt: now.subtract(const Duration(hours: 9)),
        ),
        PlantAlert(
          id: 'ALT-003',
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.warning,
          title: 'Bateria baixa — Antena 3',
          description: 'Antena RFID zona Qualidade com 12% de carga',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 40)),
        ),
      ];

  static List<Antenna> antennas() => <Antenna>[
        Antenna(
          id: 'ANT-01',
          name: 'Antena 1',
          zoneId: 'ZN-001',
          battery: 92,
          rssi: -48,
          readsToday: 1284,
        ),
        Antenna(
          id: 'ANT-02',
          name: 'Antena 2',
          zoneId: 'ZN-002',
          battery: 78,
          rssi: -52,
          readsToday: 1107,
        ),
        Antenna(
          id: 'ANT-03',
          name: 'Antena 3',
          zoneId: 'ZN-003',
          battery: 12,
          rssi: -61,
          readsToday: 964,
        ),
        Antenna(
          id: 'ANT-04',
          name: 'Antena 4',
          zoneId: 'ZN-004',
          battery: 66,
          rssi: -57,
          readsToday: 402,
        ),
        Antenna(
          id: 'ANT-05',
          name: 'Antena 5',
          zoneId: 'ZN-005',
          battery: 88,
          rssi: -45,
          readsToday: 1731,
        ),
      ];

  /// Operadores usados pelo simulador de leituras.
  static const List<String> operators = <String>[
    'Carlos M.',
    'Julia F.',
    'Pedro S.',
    'Ana R.',
    'Marcos L.',
    'Rafael T.',
  ];
}
