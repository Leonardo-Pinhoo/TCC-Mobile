import 'package:flutter/material.dart';

@immutable
class Antenna {
  const Antenna({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.battery,
    required this.rssi,
    this.online = true,
    this.readsToday = 0,
  });

  final String id;
  final String name;
  final String zoneId;

  /// Carga da bateria em porcentagem (0-100).
  final int battery;

  /// Intensidade do sinal em dBm (valor negativo).
  final int rssi;
  final bool online;
  final int readsToday;

  bool get lowBattery => battery <= 20;

  Antenna copyWith({int? battery, int? rssi, bool? online, int? readsToday}) {
    return Antenna(
      id: id,
      name: name,
      zoneId: zoneId,
      battery: battery ?? this.battery,
      rssi: rssi ?? this.rssi,
      online: online ?? this.online,
      readsToday: readsToday ?? this.readsToday,
    );
  }
}
