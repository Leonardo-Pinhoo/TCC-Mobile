import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/tool.dart';
import '../../../data/models/zone.dart';

/// Cartão de ferramenta do inventário, com os quatro campos de rastreio.
class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.tool, this.onTap});

  final Tool tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Zone zone = zoneById(tool.zoneId);
    final bool overdue = tool.maintenanceOverdue;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  tool.name,
                  style: AppText.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label: tool.status.shortLabel,
                color: tool.status.colorIn(context.colors),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${tool.id} · ${tool.tag}', style: context.texts.code),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: LabeledValue(
                  label: 'Zona',
                  value: tool.zoneId == null ? '—' : zone.name,
                  valueColor:
                      tool.zoneId == null ? context.colors.textMuted : zone.accentIn(context.colors),
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: 'Responsável',
                  value: tool.holder ?? '—',
                  valueColor: tool.holder == null ? context.colors.textMuted : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: LabeledValue(
                  label: 'Próx. manutenção',
                  value: tool.nextMaintenance == null
                      ? '—'
                      : (overdue ? 'Vencida' : Fmt.isoDate(tool.nextMaintenance!)),
                  valueColor: overdue ? context.colors.maintenance : null,
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: 'Última leitura',
                  value: Fmt.timeAgo(tool.lastRead),
                  valueColor: tool.status == ToolStatus.missing
                      ? context.colors.missing
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
