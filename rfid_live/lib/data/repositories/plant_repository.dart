import 'dart:math';

import '../models/antenna.dart';
import '../models/movement.dart';
import '../models/plant_alert.dart';
import '../models/tool.dart';
import '../models/zone.dart';
import '../seed_data.dart';

/// Violação de uma regra de negócio do middleware RFID.
class PlantException implements Exception {
  PlantException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uma leitura bruta de etiqueta capturada por uma antena.
class TagReading {
  TagReading({
    required this.toolId,
    required this.toolName,
    required this.tag,
    required this.antennaId,
    required this.zoneId,
    required this.rssi,
    required this.timestamp,
  });

  final String toolId;
  final String toolName;
  final String tag;
  final String antennaId;
  final String? zoneId;
  final int rssi;
  final DateTime timestamp;
}

/// Indicadores consolidados da planta (usados no painel e nos gráficos de BI).
class PlantStats {
  const PlantStats({
    required this.total,
    required this.inUse,
    required this.available,
    required this.maintenance,
    required this.missing,
    required this.movementsToday,
    required this.assetValue,
    required this.trackedAssetValue,
    required this.overdueMaintenance,
    required this.activeAlerts,
    required this.usageMinutesToday,
  });

  final int total;
  final int inUse;
  final int available;
  final int maintenance;
  final int missing;
  final int movementsToday;
  final double assetValue;
  final double trackedAssetValue;
  final int overdueMaintenance;
  final int activeAlerts;
  final int usageMinutesToday;

  /// Percentual de ferramentas em operação no momento.
  double get utilizationRate => total == 0 ? 0 : inUse / total;

  /// Percentual do patrimônio efetivamente visível pelas antenas.
  double get visibilityRate => total == 0 ? 0 : (total - missing) / total;

  /// Percentual de ferramentas prontas para uso.
  double get readinessRate => total == 0 ? 0 : (inUse + available) / total;

  int get count => total;
}

/// Fonte de dados em memória que simula o middleware RFID da planta.
///
/// Em produção este repositório seria substituído por chamadas HTTP/MQTT ao
/// concentrador das antenas — a interface pública permaneceria a mesma.
class PlantRepository {
  PlantRepository({DateTime? now, Random? random})
      : _random = random ?? Random(),
        _tools = SeedData.tools(now ?? DateTime.now()),
        _movements = SeedData.movements(now ?? DateTime.now()),
        _alerts = SeedData.alerts(now ?? DateTime.now()),
        _antennas = SeedData.antennas();

  final Random _random;
  final List<Tool> _tools;
  final List<Movement> _movements;
  final List<PlantAlert> _alerts;
  final List<Antenna> _antennas;
  final List<TagReading> _readings = <TagReading>[];

  int _sequence = 100;

  List<Tool> get tools => List<Tool>.unmodifiable(_tools);
  List<Movement> get movements => List<Movement>.unmodifiable(_movements);
  List<PlantAlert> get alerts => List<PlantAlert>.unmodifiable(_alerts);
  List<Antenna> get antennas => List<Antenna>.unmodifiable(_antennas);
  List<TagReading> get readings => List<TagReading>.unmodifiable(_readings);

  List<PlantAlert> get activeAlerts =>
      _alerts.where((PlantAlert a) => !a.resolved).toList();

  Tool? toolById(String id) {
    for (final Tool tool in _tools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  /// Formato canônico do EPC lido pelas antenas: `E2:XX:XX:XX` em hexadecimal.
  static final RegExp epcPattern = RegExp(r'^E2(:[0-9A-F]{2}){3}$');

  static bool isValidEpc(String tag) =>
      epcPattern.hasMatch(tag.trim().toUpperCase());

  /// Busca a ferramenta dona de um EPC. O EPC é único na planta: duas
  /// etiquetas com o mesmo código tornariam a leitura das antenas ambígua.
  Tool? toolByTag(String tag) {
    final String normalized = tag.trim().toUpperCase();
    for (final Tool tool in _tools) {
      if (tool.tag.toUpperCase() == normalized) return tool;
    }
    return null;
  }

  Antenna? antennaById(String id) {
    for (final Antenna antenna in _antennas) {
      if (antenna.id == id) return antenna;
    }
    return null;
  }

  Antenna? antennaOfZone(String? zoneId) {
    if (zoneId == null) return null;
    for (final Antenna antenna in _antennas) {
      if (antenna.zoneId == zoneId) return antenna;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  /// Busca por nome, código patrimonial ou EPC da etiqueta, com filtro opcional.
  List<Tool> search({String query = '', ToolStatus? status}) {
    final String q = query.trim().toLowerCase();
    return _tools.where((Tool tool) {
      final bool matchesStatus = status == null || tool.status == status;
      if (!matchesStatus) return false;
      if (q.isEmpty) return true;
      return tool.name.toLowerCase().contains(q) ||
          tool.id.toLowerCase().contains(q) ||
          tool.tag.toLowerCase().contains(q) ||
          tool.category.toLowerCase().contains(q) ||
          (tool.holder ?? '').toLowerCase().contains(q) ||
          zoneById(tool.zoneId).name.toLowerCase().contains(q);
    }).toList();
  }

  List<Tool> toolsInZone(String zoneId) =>
      _tools.where((Tool tool) => tool.zoneId == zoneId).toList();

  List<Tool> get unlocatedTools =>
      _tools.where((Tool tool) => tool.zoneId == null).toList();

  List<Movement> movementsOfTool(String toolId) =>
      _movements.where((Movement m) => m.toolId == toolId).toList();

  int countByStatus(ToolStatus status) =>
      _tools.where((Tool tool) => tool.status == status).length;

  PlantStats get stats {
    final DateTime now = DateTime.now();
    final DateTime dayStart = DateTime(now.year, now.month, now.day);
    return PlantStats(
      total: _tools.length,
      inUse: countByStatus(ToolStatus.inUse),
      available: countByStatus(ToolStatus.available),
      maintenance: countByStatus(ToolStatus.maintenance),
      missing: countByStatus(ToolStatus.missing),
      movementsToday: _movements
          .where((Movement m) => m.timestamp.isAfter(dayStart))
          .length,
      assetValue: _tools.fold<double>(0, (double sum, Tool t) => sum + t.assetValue),
      trackedAssetValue: _tools
          .where((Tool t) => t.status != ToolStatus.missing)
          .fold<double>(0, (double sum, Tool t) => sum + t.assetValue),
      overdueMaintenance:
          _tools.where((Tool t) => t.maintenanceOverdue).length,
      activeAlerts: activeAlerts.length,
      usageMinutesToday:
          _tools.fold<int>(0, (int sum, Tool t) => sum + t.usageMinutesToday),
    );
  }

  /// Movimentações agrupadas por hora do dia corrente (0h-23h).
  List<int> movementsByHour() {
    final DateTime now = DateTime.now();
    final DateTime dayStart = DateTime(now.year, now.month, now.day);
    final List<int> buckets = List<int>.filled(24, 0);
    for (final Movement movement in _movements) {
      if (movement.timestamp.isAfter(dayStart)) {
        buckets[movement.timestamp.hour]++;
      }
    }
    return buckets;
  }

  /// Ranking de ferramentas com mais movimentações registradas.
  List<MapEntry<Tool, int>> topMovedTools({int limit = 5}) {
    final Map<String, int> counters = <String, int>{};
    for (final Movement movement in _movements) {
      counters[movement.toolId] = (counters[movement.toolId] ?? 0) + 1;
    }
    final List<MapEntry<Tool, int>> ranking = <MapEntry<Tool, int>>[];
    counters.forEach((String toolId, int count) {
      final Tool? tool = toolById(toolId);
      if (tool != null) ranking.add(MapEntry<Tool, int>(tool, count));
    });
    ranking.sort((MapEntry<Tool, int> a, MapEntry<Tool, int> b) =>
        b.value.compareTo(a.value));
    return ranking.take(limit).toList();
  }

  /// Ocupação por zona, sempre na ordem oficial das áreas da planta.
  Map<Zone, List<Tool>> toolsGroupedByZone() {
    final Map<Zone, List<Tool>> grouped = <Zone, List<Tool>>{};
    for (final Zone zone in kZones) {
      grouped[zone] = toolsInZone(zone.id);
    }
    final List<Tool> unlocated = unlocatedTools;
    if (unlocated.isNotEmpty) {
      grouped[kUnknownZone] = unlocated;
    }
    return grouped;
  }

  // ---------------------------------------------------------------------------
  // Operações
  // ---------------------------------------------------------------------------

  String _nextId(String prefix) {
    _sequence++;
    return '$prefix-${_sequence.toString().padLeft(3, '0')}';
  }

  /// Próximo código patrimonial livre, derivado do maior `FER-xxx` existente.
  ///
  /// Contar a lista (`length + 1`) reaproveitaria um código já usado assim que
  /// uma ferramenta fosse baixada do inventário.
  String _nextToolId() {
    int highest = 0;
    for (final Tool tool in _tools) {
      final int? number = int.tryParse(tool.id.split('-').last);
      if (number != null && number > highest) highest = number;
    }
    return 'FER-${(highest + 1).toString().padLeft(3, '0')}';
  }

  void _replaceTool(Tool updated) {
    final int index = _tools.indexWhere((Tool t) => t.id == updated.id);
    if (index >= 0) _tools[index] = updated;
  }

  void _pushMovement(Movement movement) {
    _movements.insert(0, movement);
    if (_movements.length > 250) _movements.removeLast();
  }

  void _pushReading(TagReading reading) {
    _readings.insert(0, reading);
    if (_readings.length > 60) _readings.removeLast();
  }

  void _pushAlert(PlantAlert alert) {
    _alerts.insert(0, alert);
    if (_alerts.length > 120) _alerts.removeLast();
  }

  bool _hasActiveAlert(AlertKind kind, {String? toolId}) {
    return _alerts.any((PlantAlert a) =>
        !a.resolved && a.kind == kind && (toolId == null || a.toolId == toolId));
  }

  void _resolveAlertsOf(AlertKind kind, {String? toolId}) {
    for (int i = 0; i < _alerts.length; i++) {
      final PlantAlert alert = _alerts[i];
      if (!alert.resolved &&
          alert.kind == kind &&
          (toolId == null || alert.toolId == toolId)) {
        _alerts[i] = alert.copyWith(resolved: true, resolvedAt: DateTime.now());
      }
    }
  }

  /// Registra a transferência de uma ferramenta para outra zona.
  Movement registerMovement({
    required String toolId,
    required String toZoneId,
    required String user,
    MovementType? type,
    DateTime? at,
  }) {
    final Tool tool = toolById(toolId)!;
    final DateTime now = at ?? DateTime.now();
    final Zone destination = zoneById(toZoneId);

    final MovementType resolvedType = type ??
        switch (destination.kind) {
          ZoneKind.storage => MovementType.checkin,
          ZoneKind.maintenance => MovementType.maintenance,
          _ => tool.zoneId == null ? MovementType.reading : MovementType.transfer,
        };

    final ToolStatus newStatus = switch (destination.kind) {
      ZoneKind.storage => ToolStatus.available,
      ZoneKind.maintenance => ToolStatus.maintenance,
      _ => ToolStatus.inUse,
    };

    final Movement movement = Movement(
      id: _nextId('MOV'),
      toolId: tool.id,
      toolName: tool.name,
      fromZoneId: tool.zoneId,
      toZoneId: toZoneId,
      user: user,
      type: resolvedType,
      antennaId: antennaOfZone(toZoneId)?.id,
      timestamp: now,
    );

    _replaceTool(
      tool.copyWith(
        zoneId: toZoneId,
        status: newStatus,
        lastRead: now,
        holder: newStatus == ToolStatus.available ? null : user,
        clearHolder: newStatus == ToolStatus.available,
      ),
    );
    _pushMovement(movement);

    if (tool.status == ToolStatus.missing) {
      _resolveAlertsOf(AlertKind.toolMissing, toolId: tool.id);
    }
    return movement;
  }

  /// Conclui a manutenção e devolve a ferramenta ao almoxarifado.
  void finishMaintenance({required String toolId, required String user}) {
    final Tool tool = toolById(toolId)!;
    final DateTime now = DateTime.now();
    _replaceTool(
      tool.copyWith(
        status: ToolStatus.available,
        zoneId: 'ZN-005',
        lastRead: now,
        clearHolder: true,
        nextMaintenance: now.add(const Duration(days: 90)),
      ),
    );
    _pushMovement(
      Movement(
        id: _nextId('MOV'),
        toolId: tool.id,
        toolName: tool.name,
        fromZoneId: tool.zoneId,
        toZoneId: 'ZN-005',
        user: user,
        type: MovementType.checkin,
        antennaId: 'ANT-05',
        timestamp: now,
      ),
    );
    _resolveAlertsOf(AlertKind.maintenanceOverdue, toolId: tool.id);
  }

  /// Dispara uma varredura das antenas procurando uma etiqueta específica.
  ///
  /// Retorna a leitura encontrada ou `null` quando a etiqueta não responde.
  TagReading? locate(String toolId) {
    final Tool tool = toolById(toolId)!;
    if (tool.zoneId == null) return null;
    final Antenna? antenna = antennaOfZone(tool.zoneId);
    final TagReading reading = TagReading(
      toolId: tool.id,
      toolName: tool.name,
      tag: tool.tag,
      antennaId: antenna?.id ?? 'ANT-00',
      zoneId: tool.zoneId,
      rssi: (antenna?.rssi ?? -60) + _random.nextInt(6) - 3,
      timestamp: DateTime.now(),
    );
    _replaceTool(tool.copyWith(lastRead: reading.timestamp));
    _pushReading(reading);
    return reading;
  }

  /// Marca uma ferramenta perdida como reencontrada em uma zona.
  void markAsFound({
    required String toolId,
    required String zoneId,
    required String user,
  }) {
    registerMovement(toolId: toolId, toZoneId: zoneId, user: user);
  }

  /// Coloca a ferramenta em manutenção corretiva/preventiva.
  void sendToMaintenance({required String toolId, required String user}) {
    registerMovement(
      toolId: toolId,
      toZoneId: 'ZN-004',
      user: user,
      type: MovementType.maintenance,
    );
  }

  Tool addTool({
    required String name,
    required String tag,
    required String zoneId,
    required String category,
    required double assetValue,
    required String criticality,
    required String user,
  }) {
    final DateTime now = DateTime.now();
    final String normalizedTag = tag.trim().toUpperCase();

    if (!isValidEpc(normalizedTag)) {
      throw PlantException('EPC inválido. Use o formato E2:XX:XX:XX.');
    }
    final Tool? duplicate = toolByTag(normalizedTag);
    if (duplicate != null) {
      throw PlantException(
        'O EPC $normalizedTag já está vinculado a ${duplicate.id}.',
      );
    }

    final Tool tool = Tool(
      id: _nextToolId(),
      name: name,
      tag: normalizedTag,
      status: zoneById(zoneId).kind == ZoneKind.storage
          ? ToolStatus.available
          : ToolStatus.inUse,
      zoneId: zoneId,
      lastRead: now,
      nextMaintenance: now.add(const Duration(days: 90)),
      category: category,
      assetValue: assetValue,
      criticality: criticality,
    );
    _tools.add(tool);
    _pushMovement(
      Movement(
        id: _nextId('MOV'),
        toolId: tool.id,
        toolName: tool.name,
        toZoneId: zoneId,
        user: user,
        type: MovementType.register,
        antennaId: antennaOfZone(zoneId)?.id,
        timestamp: now,
      ),
    );
    return tool;
  }

  void resolveAlert(String alertId) {
    final int index = _alerts.indexWhere((PlantAlert a) => a.id == alertId);
    if (index < 0) return;
    _alerts[index] =
        _alerts[index].copyWith(resolved: true, resolvedAt: DateTime.now());
  }

  void resolveAllAlerts() {
    for (int i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].resolved) {
        _alerts[i] =
            _alerts[i].copyWith(resolved: true, resolvedAt: DateTime.now());
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Simulação do fluxo RFID em tempo real
  // ---------------------------------------------------------------------------

  /// Avança a simulação em um passo e devolve uma descrição do evento gerado,
  /// ou `null` quando o passo produziu apenas leituras de rotina.
  String? tick() {
    final int roll = _random.nextInt(100);
    if (roll < 62) {
      _simulateReading();
      return null;
    }
    if (roll < 84) return _simulateMovement();
    if (roll < 94) return _simulateBatteryDrain();
    return _simulateSignalLoss();
  }

  void _simulateReading() {
    final List<Tool> located =
        _tools.where((Tool t) => t.zoneId != null).toList();
    if (located.isEmpty) return;
    final Tool tool = located[_random.nextInt(located.length)];
    final Antenna? antenna = antennaOfZone(tool.zoneId);
    final DateTime now = DateTime.now();
    _replaceTool(
      tool.copyWith(
        lastRead: now,
        usageMinutesToday: tool.status == ToolStatus.inUse
            ? tool.usageMinutesToday + 1
            : tool.usageMinutesToday,
      ),
    );
    if (antenna != null) {
      _replaceAntenna(antenna.copyWith(readsToday: antenna.readsToday + 1));
    }
    _pushReading(
      TagReading(
        toolId: tool.id,
        toolName: tool.name,
        tag: tool.tag,
        antennaId: antenna?.id ?? 'ANT-00',
        zoneId: tool.zoneId,
        rssi: (antenna?.rssi ?? -58) + _random.nextInt(8) - 4,
        timestamp: now,
      ),
    );
  }

  String? _simulateMovement() {
    final List<Tool> movable = _tools
        .where((Tool t) =>
            t.status == ToolStatus.inUse || t.status == ToolStatus.available)
        .toList();
    if (movable.isEmpty) return null;
    final Tool tool = movable[_random.nextInt(movable.length)];
    final List<Zone> destinations =
        kZones.where((Zone z) => z.id != tool.zoneId).toList();
    final Zone destination = destinations[_random.nextInt(destinations.length)];
    final String user =
        SeedData.operators[_random.nextInt(SeedData.operators.length)];
    registerMovement(
      toolId: tool.id,
      toZoneId: destination.id,
      user: user,
    );
    return '${tool.name} → ${destination.name} ($user)';
  }

  void _replaceAntenna(Antenna updated) {
    final int index = _antennas.indexWhere((Antenna a) => a.id == updated.id);
    if (index >= 0) _antennas[index] = updated;
  }

  String? _simulateBatteryDrain() {
    final Antenna antenna = _antennas[_random.nextInt(_antennas.length)];
    final int battery = (antenna.battery - 1).clamp(0, 100);
    _replaceAntenna(antenna.copyWith(battery: battery));
    if (battery <= 20 &&
        !_hasActiveAlert(AlertKind.lowBattery) &&
        antenna.battery > 20) {
      _pushAlert(
        PlantAlert(
          id: _nextId('ALT'),
          kind: AlertKind.lowBattery,
          severity: AlertSeverity.warning,
          title: 'Bateria baixa — ${antenna.name}',
          description:
              'Antena RFID zona ${zoneById(antenna.zoneId).name} com $battery% de carga',
          createdAt: DateTime.now(),
        ),
      );
      return 'Bateria baixa na ${antenna.name}';
    }
    return null;
  }

  String? _simulateSignalLoss() {
    if (countByStatus(ToolStatus.missing) >= 2) return null;
    final List<Tool> candidates = _tools
        .where((Tool t) =>
            t.status == ToolStatus.inUse || t.status == ToolStatus.available)
        .toList();
    if (candidates.isEmpty) return null;
    final Tool tool = candidates[_random.nextInt(candidates.length)];
    _replaceTool(
      tool.copyWith(
        status: ToolStatus.missing,
        clearZone: true,
        clearHolder: true,
      ),
    );
    if (!_hasActiveAlert(AlertKind.toolMissing, toolId: tool.id)) {
      _pushAlert(
        PlantAlert(
          id: _nextId('ALT'),
          kind: AlertKind.toolMissing,
          severity: AlertSeverity.critical,
          title: 'Ferramenta não localizada',
          description:
              '${tool.name} (${tool.id}) perdeu sinal em ${zoneById(tool.zoneId).name}',
          toolId: tool.id,
          createdAt: DateTime.now(),
        ),
      );
    }
    return '${tool.name} saiu da cobertura das antenas';
  }
}
