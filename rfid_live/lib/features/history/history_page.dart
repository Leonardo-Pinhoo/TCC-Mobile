import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/live_header.dart';
import '../../data/models/movement.dart';
import '../../data/models/tool.dart';
import '../../data/models/zone.dart';
import '../../data/repositories/plant_repository.dart';
import '../../state/plant_controller.dart';
import '../dashboard/widgets/dashboard_widgets.dart';
import '../inventory/tool_details_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _showIndicators = false;
  MovementType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();

    return Column(
      children: <Widget>[
        LiveHeader(
          title: 'Histórico',
          subtitle: 'Rastro completo das etiquetas',
          refreshing: plant.refreshing,
          onRefresh: plant.refresh,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: false,
                label: Text('Movimentações', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Indicadores', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: <bool>{_showIndicators},
            showSelectedIcon: false,
            onSelectionChanged: (Set<bool> selection) =>
                setState(() => _showIndicators = selection.first),
          ),
        ),
        Expanded(
          child: _showIndicators
              ? _IndicatorsView(plant: plant)
              : _MovementsView(
                  plant: plant,
                  typeFilter: _typeFilter,
                  onFilterChanged: (MovementType? type) =>
                      setState(() => _typeFilter = type),
                ),
        ),
      ],
    );
  }
}

class _MovementsView extends StatelessWidget {
  const _MovementsView({
    required this.plant,
    required this.typeFilter,
    required this.onFilterChanged,
  });

  final PlantController plant;
  final MovementType? typeFilter;
  final ValueChanged<MovementType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final List<Movement> movements = typeFilter == null
        ? plant.movements
        : plant.movements
            .where((Movement m) => m.type == typeFilter)
            .toList();

    final Map<String, List<Movement>> grouped = <String, List<Movement>>{};
    for (final Movement movement in movements) {
      final String key = Fmt.dayLabel(movement.timestamp);
      grouped.putIfAbsent(key, () => <Movement>[]).add(movement);
    }

    return RefreshIndicator(
      onRefresh: plant.refresh,
      color: context.colors.primary,
      backgroundColor: context.colors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: <Widget>[
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _TypeChip(
                  label: 'Tudo',
                  selected: typeFilter == null,
                  onTap: () => onFilterChanged(null),
                ),
                ...MovementType.values
                    .where((MovementType t) => t != MovementType.reading)
                    .map(
                      (MovementType type) => _TypeChip(
                        label: type.label,
                        selected: typeFilter == type,
                        color: type.colorIn(context.colors),
                        onTap: () => onFilterChanged(type),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (movements.isEmpty)
            const EmptyState(
              icon: Icons.history_toggle_off,
              title: 'Sem registros',
              message: 'Nenhuma movimentação para o filtro selecionado.',
            )
          else
            ...grouped.entries.map(
              (MapEntry<String, List<Movement>> entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SectionCard(
                  title: entry.key,
                  trailing: Text('${entry.value.length}', style: context.texts.label),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < entry.value.length; i++) ...<Widget>[
                        MovementRow(
                          movement: entry.value[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ToolDetailsPage(
                                toolId: entry.value[i].toolId,
                              ),
                            ),
                          ),
                        ),
                        if (i != entry.value.length - 1)
                          Divider(color: context.colors.border),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Nulo usa o acento do tema. Valor padrao de parametro precisa ser
  /// constante, e a cor do tema nao e.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? context.colors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? accent : context.colors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: selected ? accent : context.colors.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? context.colors.onAccent(accent)
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visão analítica: distribuição por hora, ranking e ocupação por zona.
class _IndicatorsView extends StatelessWidget {
  const _IndicatorsView({required this.plant});

  final PlantController plant;

  @override
  Widget build(BuildContext context) {
    final PlantStats stats = plant.stats;
    final List<int> byHour = plant.movementsByHour();
    final List<MapEntry<Tool, int>> ranking = plant.topMovedTools();
    final int maxRank =
        ranking.isEmpty ? 0 : ranking.first.value;
    final Map<Zone, List<Tool>> byZone = plant.toolsGroupedByZone();
    final int maxZone = byZone.values.fold<int>(
      0,
      (int max, List<Tool> tools) => tools.length > max ? tools.length : max,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniStat(
                label: 'Movimentações hoje',
                value: '${stats.movementsToday}',
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Horas de uso',
                value: Fmt.duration(stats.usageMinutesToday),
                color: context.colors.available,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Movimentações por hora',
          trailing: Text('24h', style: context.texts.label),
          child: HourlyBarChart(values: byHour),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Disponibilidade da operação',
          child: Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: MetricRing(
                    ratio: stats.readinessRate,
                    value: Fmt.percent(stats.readinessRate),
                    label: 'Prontidão',
                    color: context.colors.available,
                    size: 92,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: MetricRing(
                    ratio: stats.utilizationRate,
                    value: Fmt.percent(stats.utilizationRate),
                    label: 'Utilização',
                    color: context.colors.inUse,
                    size: 92,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Ferramentas mais movimentadas',
          child: ranking.isEmpty
              ? const EmptyState(
                  icon: Icons.bar_chart,
                  title: 'Sem dados suficientes',
                )
              : Column(
                  children: ranking
                      .map(
                        (MapEntry<Tool, int> entry) => RankingBar(
                          label: entry.key.name,
                          caption: entry.key.id,
                          value: entry.value,
                          maxValue: maxRank,
                          color: entry.key.status.colorIn(context.colors),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Ocupação por zona',
          child: Column(
            children: byZone.entries
                .map(
                  (MapEntry<Zone, List<Tool>> entry) => RankingBar(
                    label: entry.key.name,
                    caption:
                        '${entry.value.length} de ${plant.tools.length}',
                    value: entry.value.length,
                    maxValue: maxZone,
                    color: entry.key.accentIn(context.colors),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Patrimônio sob rastreio',
          child: Column(
            children: <Widget>[
              _KeyValue(
                label: 'Valor total cadastrado',
                value: Fmt.currency(stats.assetValue),
              ),
              _KeyValue(
                label: 'Valor com leitura ativa',
                value: Fmt.currency(stats.trackedAssetValue),
                color: context.colors.available,
              ),
              _KeyValue(
                label: 'Exposição sem rastreio',
                value: Fmt.currency(stats.assetValue - stats.trackedAssetValue),
                color: stats.assetValue == stats.trackedAssetValue
                    ? context.colors.available
                    : context.colors.missing,
              ),
              _KeyValue(
                label: 'Visibilidade das etiquetas',
                value: Fmt.percent(stats.visibilityRate, decimals: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: context.texts.label),
          const SizedBox(height: 8),
          Text(value, style: AppText.metric.copyWith(fontSize: 22, color: color)),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: context.texts.caption.copyWith(color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: AppText.value.copyWith(color: color)),
        ],
      ),
    );
  }
}
