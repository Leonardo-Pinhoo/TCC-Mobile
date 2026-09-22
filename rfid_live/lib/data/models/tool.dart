import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum ToolStatus { inUse, available, maintenance, missing }

extension ToolStatusX on ToolStatus {
  String get label => switch (this) {
        ToolStatus.inUse => 'Em uso',
        ToolStatus.available => 'Disponível',
        ToolStatus.maintenance => 'Manutenção',
        ToolStatus.missing => 'Não localizada',
      };

  /// Texto curto usado nos chips de filtro e nas badges dos cartões.
  String get shortLabel => switch (this) {
        ToolStatus.inUse => 'Em uso',
        ToolStatus.available => 'Disponível',
        ToolStatus.maintenance => 'Manutenção',
        ToolStatus.missing => 'Não local.',
      };

  Color colorIn(AppPalette palette) => switch (this) {
        ToolStatus.inUse => palette.inUse,
        ToolStatus.available => palette.available,
        ToolStatus.maintenance => palette.maintenance,
        ToolStatus.missing => palette.missing,
      };

  IconData get icon => switch (this) {
        ToolStatus.inUse => Icons.handyman_outlined,
        ToolStatus.available => Icons.check_circle_outline,
        ToolStatus.maintenance => Icons.build_circle_outlined,
        ToolStatus.missing => Icons.help_outline,
      };
}

@immutable
class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.tag,
    required this.status,
    required this.zoneId,
    required this.lastRead,
    this.holder,
    this.nextMaintenance,
    this.category = 'Geral',
    this.assetValue = 0,
    this.criticality = 'Media',
    this.usageMinutesToday = 0,
  });

  /// Codigo patrimonial (ex.: FER-001).
  final String id;
  final String name;

  /// EPC da etiqueta RFID (ex.: E2:00:1A:B3).
  final String tag;
  final ToolStatus status;

  /// Nulo quando a ferramenta esta fora da cobertura das antenas.
  final String? zoneId;
  final DateTime lastRead;
  final String? holder;
  final DateTime? nextMaintenance;
  final String category;
  final double assetValue;
  final String criticality;
  final int usageMinutesToday;

  bool get maintenanceOverdue =>
      nextMaintenance != null && nextMaintenance!.isBefore(DateTime.now());

  int get maintenanceDaysLate {
    if (!maintenanceOverdue) return 0;
    return DateTime.now().difference(nextMaintenance!).inDays;
  }

  Tool copyWith({
    String? name,
    String? tag,
    ToolStatus? status,
    String? zoneId,
    bool clearZone = false,
    DateTime? lastRead,
    String? holder,
    bool clearHolder = false,
    DateTime? nextMaintenance,
    bool clearMaintenance = false,
    String? category,
    double? assetValue,
    String? criticality,
    int? usageMinutesToday,
  }) {
    return Tool(
      id: id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      zoneId: clearZone ? null : (zoneId ?? this.zoneId),
      lastRead: lastRead ?? this.lastRead,
      holder: clearHolder ? null : (holder ?? this.holder),
      nextMaintenance:
          clearMaintenance ? null : (nextMaintenance ?? this.nextMaintenance),
      category: category ?? this.category,
      assetValue: assetValue ?? this.assetValue,
      criticality: criticality ?? this.criticality,
      usageMinutesToday: usageMinutesToday ?? this.usageMinutesToday,
    );
  }
}
