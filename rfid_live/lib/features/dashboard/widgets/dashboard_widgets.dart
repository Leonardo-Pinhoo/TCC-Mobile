import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/movement.dart';
import '../../../data/models/plant_alert.dart';
import '../../../data/models/zone.dart';

/// Cartão de indicador do topo do painel (valor grande + rótulo).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.label),
          const SizedBox(height: 10),
          Text(value, style: AppText.metric.copyWith(color: color)),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: AppText.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
    return Semantics(
      label: caption == null ? '$label: $value' : '$label: $value. $caption',
      button: onTap != null,
      excludeSemantics: true,
      child: card,
    );
  }
}

/// Linha da lista "Últimas movimentações".
class MovementRow extends StatelessWidget {
  const MovementRow({
    super.key,
    required this.movement,
    this.showDay = false,
    this.onTap,
  });

  final Movement movement;
  final bool showDay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Zone from = zoneById(movement.fromZoneId);
    final Zone to = zoneById(movement.toZoneId);
    final bool hasOrigin = movement.fromZoneId != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppText.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(movement.type.icon, size: 14, color: movement.type.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    movement.toolName,
                    style: AppText.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  showDay
                      ? '${Fmt.dayLabel(movement.timestamp)} ${Fmt.hhmm(movement.timestamp)}'
                      : Fmt.hhmm(movement.timestamp),
                  style: AppText.codeMono,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (hasOrigin) ...<Widget>[
                    Text(
                      from.name,
                      style: AppText.caption.copyWith(color: from.accent),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_right_alt,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  Text(
                    to.name,
                    style: AppText.caption.copyWith(color: to.accent),
                  ),
                  Text(
                    ' · ${movement.user}',
                    style: AppText.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de alerta com faixa colorida à esquerda.
class AlertRow extends StatelessWidget {
  const AlertRow({
    super.key,
    required this.alert,
    this.onResolve,
    this.onTap,
    this.dense = false,
  });

  final PlantAlert alert;
  final VoidCallback? onResolve;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color =
        alert.resolved ? AppColors.textMuted : alert.severity.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: alert.resolved ? 0.04 : 0.09),
        borderRadius: BorderRadius.circular(AppText.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppText.radius),
          child: Container(
            padding: EdgeInsets.fromLTRB(12, dense ? 10 : 12, 10, dense ? 10 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppText.radius),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(alert.severity.icon, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        alert.title,
                        style: AppText.value.copyWith(
                          color: alert.resolved
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: alert.resolved
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.description,
                        style: AppText.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      if (!dense) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          '${alert.severity.label} · ${Fmt.timeAgo(alert.createdAt)}',
                          style: AppText.codeMono.copyWith(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onResolve != null && !alert.resolved)
                  IconButton(
                    onPressed: onResolve,
                    tooltip: 'Marcar como resolvido',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 19,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
