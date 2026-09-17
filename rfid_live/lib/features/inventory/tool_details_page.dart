import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/antenna.dart';
import '../../data/models/movement.dart';
import '../../data/models/tool.dart';
import '../../data/models/zone.dart';
import '../../data/repositories/plant_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';
import '../dashboard/widgets/dashboard_widgets.dart';

class ToolDetailsPage extends StatefulWidget {
  ToolDetailsPage({
    super.key,
    required this.toolId,
    List<String>? toolIds,
    this.initialIndex = 0,
  }) : toolIds = toolIds ?? <String>[toolId];

  final String toolId;

  /// Ferramentas navegáveis por arrasto horizontal (ex.: a lista filtrada do
  /// inventário). Quando não informada, a ficha mostra só [toolId].
  final List<String> toolIds;
  final int initialIndex;

  @override
  State<ToolDetailsPage> createState() => _ToolDetailsPageState();
}

class _ToolDetailsPageState extends State<ToolDetailsPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.toolIds.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final Tool? tool = plant.toolById(widget.toolIds[_index]);

    if (tool == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Ferramenta não encontrada',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(tool.id, style: AppText.title.copyWith(fontSize: 17)),
            if (widget.toolIds.length > 1)
              Text(
                '${_index + 1} de ${widget.toolIds.length}',
                style: AppText.label,
              ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copiar EPC da etiqueta',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: tool.tag));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('EPC ${tool.tag} copiado.')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined, size: 20),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.toolIds.length,
        onPageChanged: (int page) => setState(() => _index = page),
        itemBuilder: (BuildContext context, int page) =>
            _ToolDetailsBody(toolId: widget.toolIds[page]),
      ),
    );
  }
}

class _ToolDetailsBody extends StatelessWidget {
  const _ToolDetailsBody({required this.toolId});

  final String toolId;

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final Tool? tool = plant.toolById(toolId);

    if (tool == null) {
      return const EmptyState(
        icon: Icons.error_outline,
        title: 'Ferramenta não encontrada',
      );
    }

    final Zone zone = zoneById(tool.zoneId);
    final Antenna? antenna = plant.antennaOfZone(tool.zoneId);
    final List<Movement> history = plant.movementsOfTool(tool.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: <Widget>[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(tool.name, style: AppText.title.copyWith(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge(
                    label: tool.status.label,
                    color: tool.status.color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(tool.tag, style: AppText.codeMono),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: LabeledValue(
                      label: 'Zona atual',
                      value: tool.zoneId == null ? 'Fora de cobertura' : zone.name,
                      valueColor: tool.zoneId == null
                          ? AppColors.missing
                          : zone.accent,
                    ),
                  ),
                  Expanded(
                    child: LabeledValue(
                      label: 'Responsável',
                      value: tool.holder ?? '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: LabeledValue(
                      label: 'Última leitura',
                      value: Fmt.timeAgo(tool.lastRead),
                    ),
                  ),
                  Expanded(
                    child: LabeledValue(
                      label: 'Antena',
                      value: antenna == null
                          ? '—'
                          : '${antenna.name} (${antenna.rssi} dBm)',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ActionBar(tool: tool),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Ficha técnica',
          child: Column(
            children: <Widget>[
              _SpecRow(label: 'Categoria', value: tool.category),
              _SpecRow(label: 'Criticidade', value: tool.criticality),
              _SpecRow(
                label: 'Valor do ativo',
                value: Fmt.currency(tool.assetValue),
              ),
              _SpecRow(
                label: 'Uso acumulado hoje',
                value: Fmt.duration(tool.usageMinutesToday),
              ),
              _SpecRow(
                label: 'Próxima manutenção',
                value: tool.nextMaintenance == null
                    ? '—'
                    : Fmt.isoDate(tool.nextMaintenance!),
                valueColor:
                    tool.maintenanceOverdue ? AppColors.maintenance : null,
              ),
              if (tool.maintenanceOverdue)
                _SpecRow(
                  label: 'Atraso de manutenção',
                  value: '${tool.maintenanceDaysLate} dias',
                  valueColor: AppColors.maintenance,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Histórico da ferramenta',
          trailing: Text('${history.length}', style: AppText.label),
          child: history.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  title: 'Sem movimentações registradas',
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < history.length; i++) ...<Widget>[
                      MovementRow(movement: history[i], showDay: true),
                      if (i != history.length - 1)
                        const Divider(color: AppColors.border),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.tool});

  final Tool tool;

  String _user(BuildContext context) =>
      context.read<AuthController>().user?.name ?? 'Operador';

  Future<void> _locate(BuildContext context) async {
    final PlantController plant = context.read<PlantController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TagReading? reading = plant.locate(tool.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reading == null
              ? 'Etiqueta ${tool.tag} não respondeu à varredura. Ferramenta fora da cobertura.'
              : 'Etiqueta localizada em ${zoneById(reading.zoneId).name} '
                  'pela ${plant.repository.antennaById(reading.antennaId)?.name ?? reading.antennaId} '
                  '(${reading.rssi} dBm).',
        ),
      ),
    );
  }

  Future<void> _move(BuildContext context) async {
    final PlantController plant = context.read<PlantController>();
    final String user = _user(context);
    final Zone? destination = await showModalBottomSheet<Zone>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('REGISTRAR MOVIMENTAÇÃO PARA', style: AppText.labelStrong),
            ),
            ...kZones.map(
              (Zone zone) => ListTile(
                enabled: zone.id != tool.zoneId,
                leading: StatusDot(color: zone.accent, size: 9),
                title: Text(zone.name, style: AppText.value),
                subtitle: Text(zone.description, style: AppText.codeMono),
                onTap: () => Navigator.of(context).pop(zone),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (destination == null || !context.mounted) return;
    plant.registerMovement(
      toolId: tool.id,
      toZoneId: destination.id,
      user: user,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tool.name} movida para ${destination.name}.')),
    );
  }

  void _maintenance(BuildContext context) {
    final PlantController plant = context.read<PlantController>();
    final String user = _user(context);
    final bool finishing = tool.status == ToolStatus.maintenance;
    if (finishing) {
      plant.finishMaintenance(toolId: tool.id, user: user);
    } else {
      plant.sendToMaintenance(toolId: tool.id, user: user);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          finishing
              ? 'Manutenção concluída. ${tool.name} liberada no almoxarifado.'
              : '${tool.name} enviada para a manutenção.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool inMaintenance = tool.status == ToolStatus.maintenance;
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionButton(
            icon: Icons.wifi_tethering,
            label: 'Localizar',
            color: AppColors.primary,
            onTap: () => _locate(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.swap_horiz,
            label: 'Mover',
            color: AppColors.available,
            onTap: () => _move(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: inMaintenance ? Icons.task_alt : Icons.build_outlined,
            label: inMaintenance ? 'Concluir' : 'Manutenção',
            color: AppColors.maintenance,
            onTap: () => _maintenance(context),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppText.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppText.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppText.radius),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: AppText.value.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
