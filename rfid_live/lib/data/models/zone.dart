import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Tipo de area dentro da planta industrial.
enum ZoneKind { production, quality, maintenance, storage, offline }

@immutable
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.kind,
    this.description = '',
  });

  final String id;
  final String name;
  final ZoneKind kind;
  final String description;

  /// Areas de apoio sao desenhadas com borda tracejada no mapa da planta.
  bool get dashedBorder =>
      kind == ZoneKind.maintenance || kind == ZoneKind.storage;
}

/// Cor da zona no mapa e nas listas.
///
/// Fica fora do modelo de proposito: a cor depende do tema, o dado da planta
/// nao. O [ZoneKind] ja carrega a semantica, entao a cor e derivada dele na
/// hora de desenhar.
extension ZoneAccent on Zone {
  Color accentIn(AppPalette palette) => switch (kind) {
        ZoneKind.production => palette.inUse,
        ZoneKind.quality => palette.available,
        ZoneKind.maintenance => palette.maintenance,
        ZoneKind.storage => palette.available,
        ZoneKind.offline => palette.missing,
      };
}

/// Zona virtual usada quando a etiqueta some da cobertura das antenas.
const Zone kUnknownZone = Zone(
  id: 'ZN-000',
  name: 'Fora de cobertura',
  kind: ZoneKind.offline,
  description: 'Sem leitura das antenas RFID no momento',
);

const List<Zone> kZones = <Zone>[
  Zone(
    id: 'ZN-001',
    name: 'Linha A',
    kind: ZoneKind.production,
    description: 'Linha de envase 1',
  ),
  Zone(
    id: 'ZN-002',
    name: 'Linha B',
    kind: ZoneKind.production,
    description: 'Linha de envase 2',
  ),
  Zone(
    id: 'ZN-003',
    name: 'Qualidade',
    kind: ZoneKind.quality,
    description: 'Laboratorio de controle',
  ),
  Zone(
    id: 'ZN-004',
    name: 'Manutenção',
    kind: ZoneKind.maintenance,
    description: 'Oficina de manutenção',
  ),
  Zone(
    id: 'ZN-005',
    name: 'Almoxarifado',
    kind: ZoneKind.storage,
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
