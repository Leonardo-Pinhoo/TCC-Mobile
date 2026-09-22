import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum MovementType { transfer, checkout, checkin, maintenance, reading, register }

extension MovementTypeX on MovementType {
  String get label => switch (this) {
        MovementType.transfer => 'Movimentação',
        MovementType.checkout => 'Retirada',
        MovementType.checkin => 'Devolução',
        MovementType.maintenance => 'Manutenção',
        MovementType.reading => 'Leitura RFID',
        MovementType.register => 'Cadastro',
      };

  IconData get icon => switch (this) {
        MovementType.transfer => Icons.swap_horiz,
        MovementType.checkout => Icons.logout,
        MovementType.checkin => Icons.login,
        MovementType.maintenance => Icons.build_outlined,
        MovementType.reading => Icons.sensors,
        MovementType.register => Icons.add_circle_outline,
      };

  Color colorIn(AppPalette palette) => switch (this) {
        MovementType.transfer => palette.inUse,
        MovementType.checkout => palette.maintenance,
        MovementType.checkin => palette.available,
        MovementType.maintenance => palette.maintenance,
        MovementType.reading => palette.textMuted,
        MovementType.register => palette.available,
      };
}

@immutable
class Movement {
  const Movement({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.toZoneId,
    required this.timestamp,
    required this.type,
    this.fromZoneId,
    this.user = 'Sistema',
    this.antennaId,
  });

  final String id;
  final String toolId;
  final String toolName;
  final String? fromZoneId;
  final String? toZoneId;
  final DateTime timestamp;
  final MovementType type;
  final String user;
  final String? antennaId;
}
