import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/antenna.dart';
import '../data/models/movement.dart';
import '../data/models/plant_alert.dart';
import '../data/models/tool.dart';
import '../data/models/zone.dart';
import '../data/repositories/plant_repository.dart';

/// Orquestra o repositório da planta e o "fluxo ao vivo" das antenas RFID.
class PlantController extends ChangeNotifier {
  PlantController({PlantRepository? repository, bool autoStart = true})
      : _repository = repository ?? PlantRepository() {
    _lastSync = DateTime.now();
    if (autoStart) startLiveFeed();
  }

  static const String _livePrefKey = 'rfid_live_feed_enabled';
  static const Duration tickInterval = Duration(seconds: 5);

  final PlantRepository _repository;
  Timer? _timer;
  bool _liveEnabled = true;
  bool _refreshing = false;
  late DateTime _lastSync;
  String? _lastEvent;

  PlantRepository get repository => _repository;
  bool get liveEnabled => _liveEnabled;
  bool get refreshing => _refreshing;
  DateTime get lastSync => _lastSync;
  String? get lastEvent => _lastEvent;

  List<Tool> get tools => _repository.tools;
  List<Movement> get movements => _repository.movements;
  List<PlantAlert> get alerts => _repository.alerts;
  List<PlantAlert> get activeAlerts => _repository.activeAlerts;
  List<Antenna> get antennas => _repository.antennas;
  List<TagReading> get readings => _repository.readings;
  PlantStats get stats => _repository.stats;
  int get onlineAntennas => _repository.antennas.where((Antenna a) => a.online).length;

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _liveEnabled = prefs.getBool(_livePrefKey) ?? true;
    if (_liveEnabled) {
      startLiveFeed();
    } else {
      stopLiveFeed();
    }
    notifyListeners();
  }

  void startLiveFeed() {
    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
  }

  void stopLiveFeed() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> setLiveEnabled(bool value) async {
    _liveEnabled = value;
    if (value) {
      startLiveFeed();
    } else {
      stopLiveFeed();
    }
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_livePrefKey, value);
  }

  void _onTick() {
    final String? event = _repository.tick();
    if (event != null) _lastEvent = event;
    _lastSync = DateTime.now();
    notifyListeners();
  }

  /// Força uma nova varredura completa das antenas.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    _repository.tick();
    _lastSync = DateTime.now();
    _refreshing = false;
    notifyListeners();
  }

  // --- Ações de operação -----------------------------------------------------

  void registerMovement({
    required String toolId,
    required String toZoneId,
    required String user,
    MovementType? type,
  }) {
    _repository.registerMovement(
      toolId: toolId,
      toZoneId: toZoneId,
      user: user,
      type: type,
    );
    _lastSync = DateTime.now();
    notifyListeners();
  }

  void sendToMaintenance({required String toolId, required String user}) {
    _repository.sendToMaintenance(toolId: toolId, user: user);
    notifyListeners();
  }

  void finishMaintenance({required String toolId, required String user}) {
    _repository.finishMaintenance(toolId: toolId, user: user);
    notifyListeners();
  }

  TagReading? locate(String toolId) {
    final TagReading? reading = _repository.locate(toolId);
    notifyListeners();
    return reading;
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
    final Tool tool = _repository.addTool(
      name: name,
      tag: tag,
      zoneId: zoneId,
      category: category,
      assetValue: assetValue,
      criticality: criticality,
      user: user,
    );
    notifyListeners();
    return tool;
  }

  void resolveAlert(String alertId) {
    _repository.resolveAlert(alertId);
    notifyListeners();
  }

  void resolveAllAlerts() {
    _repository.resolveAllAlerts();
    notifyListeners();
  }

  // --- Consultas -------------------------------------------------------------

  Tool? toolById(String id) => _repository.toolById(id);
  Tool? toolByTag(String tag) => _repository.toolByTag(tag);
  List<Tool> search({String query = '', ToolStatus? status}) =>
      _repository.search(query: query, status: status);
  List<Tool> toolsInZone(String zoneId) => _repository.toolsInZone(zoneId);
  Map<Zone, List<Tool>> toolsGroupedByZone() => _repository.toolsGroupedByZone();
  List<Movement> movementsOfTool(String toolId) =>
      _repository.movementsOfTool(toolId);
  List<int> movementsByHour() => _repository.movementsByHour();
  List<MapEntry<Tool, int>> topMovedTools({int limit = 5}) =>
      _repository.topMovedTools(limit: limit);
  Antenna? antennaOfZone(String? zoneId) => _repository.antennaOfZone(zoneId);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
