import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/live_header.dart';
import '../../data/models/tool.dart';
import '../../data/models/zone.dart';
import '../../data/repositories/plant_repository.dart';
import '../../state/plant_controller.dart';
import 'zone_sheet.dart';

class PlantMapPage extends StatelessWidget {
  const PlantMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final Map<Zone, List<Tool>> grouped = plant.toolsGroupedByZone();
    final List<Tool> unlocated =
        plant.tools.where((Tool t) => t.zoneId == null).toList();

    return Column(
      children: <Widget>[
        LiveHeader(
          title: 'Mapa da Planta',
          refreshing: plant.refreshing,
          onRefresh: plant.refresh,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: plant.refresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: <Widget>[
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'PLANTA INDUSTRIAL — TEMPO REAL',
                        style: AppText.labelStrong,
                      ),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: <Widget>[
                          _LegendItem(color: AppColors.inUse, label: 'Em uso'),
                          _LegendItem(color: AppColors.available, label: 'Disponível'),
                          _LegendItem(color: AppColors.missing, label: 'Perdida'),
                          _LegendItem(
                            color: AppColors.textMuted,
                            label: 'Antena RFID',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ZoneGrid(grouped: grouped),
                      if (unlocated.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        _ZoneTile(
                          zone: kUnknownZone,
                          tools: unlocated,
                          fullWidth: true,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Toque em uma zona para ver detalhes',
                          style: AppText.codeMono.copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Ferramentas por zona',
                  child: Column(
                    children: <Widget>[
                      for (final MapEntry<Zone, List<Tool>> entry
                          in grouped.entries)
                        _ZoneCountRow(zone: entry.key, tools: entry.value),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _LiveReadingsCard(readings: plant.readings),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        StatusDot(color: color, size: 6),
        const SizedBox(width: 4),
        Text(label, style: AppText.label.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _ZoneGrid extends StatelessWidget {
  const _ZoneGrid({required this.grouped});

  final Map<Zone, List<Tool>> grouped;

  @override
  Widget build(BuildContext context) {
    final List<Zone> zones =
        kZones.where((Zone z) => z.kind != ZoneKind.storage).toList();
    final List<Zone> storage =
        kZones.where((Zone z) => z.kind == ZoneKind.storage).toList();

    return Column(
      children: <Widget>[
        for (int i = 0; i < zones.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            // IntrinsicHeight mantém as duas zonas da linha com a mesma altura
            // mesmo quando uma delas quebra o texto em duas linhas.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: _ZoneTile(
                      zone: zones[i],
                      tools: grouped[zones[i]] ?? const <Tool>[],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < zones.length
                        ? _ZoneTile(
                            zone: zones[i + 1],
                            tools: grouped[zones[i + 1]] ?? const <Tool>[],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        for (final Zone zone in storage)
          _ZoneTile(
            zone: zone,
            tools: grouped[zone] ?? const <Tool>[],
            fullWidth: true,
          ),
      ],
    );
  }
}

/// Cartão de área da planta com contagem de etiquetas presentes.
class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.zone,
    required this.tools,
    this.fullWidth = false,
  });

  final Zone zone;
  final List<Tool> tools;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final int available =
        tools.where((Tool t) => t.status == ToolStatus.available).length;
    final int inUse = tools.where((Tool t) => t.status == ToolStatus.inUse).length;

    final Widget content = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: zone.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppText.radius),
        border: zone.dashedBorder
            ? null
            : Border.all(color: zone.accent.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            zone.name,
            style: TextStyle(
              color: zone.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              StatusDot(
                color: inUse > 0 ? AppColors.inUse : zone.accent,
                size: 6,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${tools.length} ferramenta${tools.length == 1 ? '' : 's'}'
                  '${available > 0 ? ' ($available disponíve${available == 1 ? 'l' : 'is'})' : ''}',
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => showZoneSheet(context, zone),
      child: zone.dashedBorder
          ? CustomPaint(
              foregroundPainter: DashedBorderPainter(
                color: zone.accent.withValues(alpha: 0.75),
              ),
              child: content,
            )
          : content,
    );
  }
}

class _ZoneCountRow extends StatelessWidget {
  const _ZoneCountRow({required this.zone, required this.tools});

  final Zone zone;
  final List<Tool> tools;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showZoneSheet(context, zone),
      borderRadius: BorderRadius.circular(AppText.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: zone.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(zone.name, style: AppText.value)),
            Text(
              '${tools.length}',
              style: TextStyle(
                color: zone.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fluxo bruto de leituras das antenas (últimos eventos capturados).
class _LiveReadingsCard extends StatelessWidget {
  const _LiveReadingsCard({required this.readings});

  final List<TagReading> readings;

  @override
  Widget build(BuildContext context) {
    final List<TagReading> latest = readings.take(6).toList();
    return SectionCard(
      title: 'Leituras ao vivo',
      trailing: const LiveDot(size: 6),
      child: latest.isEmpty
          ? Text(
              'Aguardando a próxima varredura das antenas...',
              style: AppText.codeMono,
            )
          : Column(
              children: latest
                  .map(
                    (TagReading reading) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          Text(
                            Fmt.clock(reading.timestamp),
                            style: AppText.codeMono.copyWith(fontSize: 10),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${reading.tag}  ${reading.toolName}',
                              style: AppText.codeMono.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${reading.rssi} dBm',
                            style: AppText.codeMono.copyWith(
                              fontSize: 10,
                              color: AppColors.available,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
