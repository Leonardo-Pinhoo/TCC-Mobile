import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/antenna.dart';
import '../../data/models/tool.dart';
import '../../data/models/zone.dart';
import '../../state/plant_controller.dart';
import '../inventory/tool_details_page.dart';

/// Detalhe de uma zona da planta: antena, ocupação e ferramentas presentes.
Future<void> showZoneSheet(BuildContext context, Zone zone) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    isScrollControlled: true,
    builder: (BuildContext context) => _ZoneSheet(zone: zone),
  );
}

class _ZoneSheet extends StatelessWidget {
  const _ZoneSheet({required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final List<Tool> tools = zone.id == kUnknownZone.id
        ? plant.tools.where((Tool t) => t.zoneId == null).toList()
        : plant.toolsInZone(zone.id);
    final Antenna? antenna = plant.antennaOfZone(zone.id);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  StatusDot(color: zone.accentIn(context.colors), size: 9),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          zone.name,
                          style: AppText.title.copyWith(fontSize: 18),
                        ),
                        Text(
                          zone.description,
                          style: context.texts.caption.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InfoPill(
                    label: '${tools.length} ferramenta${tools.length == 1 ? '' : 's'}',
                    color: zone.accentIn(context.colors),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (antenna != null)
                SurfaceCard(
                  color: context.colors.surfaceAlt,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.settings_input_antenna,
                        size: 18,
                        color: antenna.lowBattery
                            ? context.colors.warning
                            : context.colors.available,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${antenna.name} · ${antenna.id}',
                                style: AppText.value),
                            const SizedBox(height: 2),
                            Text(
                              'RSSI ${antenna.rssi} dBm · ${antenna.readsToday} leituras hoje',
                              style: context.texts.code,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${antenna.battery}%',
                        style: AppText.value.copyWith(
                          color: antenna.lowBattery
                              ? context.colors.warning
                              : context.colors.available,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Text('FERRAMENTAS NA ZONA', style: context.texts.labelStrong),
              const SizedBox(height: 6),
              Flexible(
                child: tools.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Zona vazia',
                        message: 'Nenhuma etiqueta lida nesta área agora.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: tools.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: context.colors.border),
                        itemBuilder: (BuildContext context, int index) {
                          final Tool tool = tools[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ToolDetailsPage(toolId: tool.id),
                                ),
                              );
                            },
                            leading: Icon(
                              tool.status.icon,
                              color: tool.status.colorIn(context.colors),
                              size: 20,
                            ),
                            title: Text(tool.name, style: AppText.value),
                            subtitle: Text(
                              '${tool.id} · ${Fmt.timeAgo(tool.lastRead)}'
                              '${tool.holder != null ? ' · ${tool.holder}' : ''}',
                              style: context.texts.code,
                            ),
                            trailing: StatusBadge(
                              label: tool.status.shortLabel,
                              color: tool.status.colorIn(context.colors),
                              dense: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
