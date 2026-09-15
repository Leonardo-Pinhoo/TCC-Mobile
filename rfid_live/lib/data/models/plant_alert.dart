import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AlertSeverity { critical, warning, info }

extension AlertSeverityX on AlertSeverity {
  String get label => switch (this) {
        AlertSeverity.critical => 'Crítico',
        AlertSeverity.warning => 'Atenção',
        AlertSeverity.info => 'Informativo',
      };

  Color get color => switch (this) {
        AlertSeverity.critical => AppColors.critical,
        AlertSeverity.warning => AppColors.warning,
        AlertSeverity.info => AppColors.info,
      };

  IconData get icon => switch (this) {
        AlertSeverity.critical => Icons.do_not_disturb_on_outlined,
        AlertSeverity.warning => Icons.warning_amber_rounded,
        AlertSeverity.info => Icons.info_outline,
      };
}

enum AlertKind { toolMissing, maintenanceOverdue, lowBattery, unauthorizedZone, antennaOffline }

extension AlertKindX on AlertKind {
  String get label => switch (this) {
        AlertKind.toolMissing => 'Ferramenta não localizada',
        AlertKind.maintenanceOverdue => 'Manutenção vencida',
        AlertKind.lowBattery => 'Bateria baixa',
        AlertKind.unauthorizedZone => 'Zona não autorizada',
        AlertKind.antennaOffline => 'Antena offline',
      };
}

@immutable
class PlantAlert {
  const PlantAlert({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.description,
    required this.createdAt,
    this.toolId,
    this.resolved = false,
    this.resolvedAt,
  });

  final String id;
  final AlertKind kind;
  final AlertSeverity severity;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? toolId;
  final bool resolved;
  final DateTime? resolvedAt;

  PlantAlert copyWith({bool? resolved, DateTime? resolvedAt}) {
    return PlantAlert(
      id: id,
      kind: kind,
      severity: severity,
      title: title,
      description: description,
      createdAt: createdAt,
      toolId: toolId,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
