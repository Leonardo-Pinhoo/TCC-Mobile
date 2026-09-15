import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tipo de area dentro da planta industrial.
enum ZoneKind { production, quality, maintenance, storage, offline }

@immutable
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.kind,
    required this.accent,
    this.description = '',
  });

  final String id;
  final String name;
  final ZoneKind kind;
  final Color accent;
  final String description;

  /// Areas de apoio sao desenhadas com borda tracejada no mapa da planta.
  bool get dashedBorder =>
      kind == ZoneKind.maintenance || kind == ZoneKind.storage;
}

/// Zona virtual usada quando a etiqueta some da cobertura das antenas.
const Zone kUnknownZone = Zone(
  id: 'ZN-000',
  name: 'Fora de cobertura',
  kind: ZoneKind.offline,
  accent: AppColors.missing,
  description: 'Sem leitura das antenas RFID no momento',
);

const List<Zone> kZones = <Zone>[
  Zone(
    id: 'ZN-001',
    name: 'Linha A',
    kind: ZoneKind.production,
    accent: AppColors.inUse,
    description: 'Linha de envase 1',
  ),
  Zone(
    id: 'ZN-002',
    name: 'Linha B',
    kind: ZoneKind.production,
    accent: AppColors.inUse,
    description: 'Linha de envase 2',
  ),
  Zone(
    id: 'ZN-003',
    name: 'Qualidade',
    kind: ZoneKind.quality,
    accent: AppColors.available,
    description: 'Laboratorio de controle',
  ),
  Zone(
    id: 'ZN-004',
    name: 'Manutenção',
    kind: ZoneKind.maintenance,
    accent: AppColors.maintenance,
    description: 'Oficina de manutenção',
  ),
  Zone(
    id: 'ZN-005',
    name: 'Almoxarifado',
    kind: ZoneKind.storage,
    accent: AppColors.available,
    description: 'Estoque central de ferramentas',
  ),
];

Zone zoneById(String? id) {
  if (id == null) return kUnknownZone;
  for (final Zone zone in kZones) {
    if (zone.id == id) return zone;
  }
  return kUnknownZone;
}
