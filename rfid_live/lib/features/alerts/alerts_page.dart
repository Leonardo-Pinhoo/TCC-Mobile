import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/live_header.dart';
import '../../data/models/plant_alert.dart';
import '../../state/plant_controller.dart';
import '../dashboard/widgets/dashboard_widgets.dart';
import '../inventory/tool_details_page.dart';

enum AlertFilter { active, resolved, all }

extension _AlertFilterX on AlertFilter {
  String get label => switch (this) {
        AlertFilter.active => 'Ativos',
        AlertFilter.resolved => 'Resolvidos',
        AlertFilter.all => 'Todos',
      };
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  AlertFilter _filter = AlertFilter.active;

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final List<PlantAlert> all = plant.alerts;
    final List<PlantAlert> visible = switch (_filter) {
      AlertFilter.active => all.where((PlantAlert a) => !a.resolved).toList(),
      AlertFilter.resolved => all.where((PlantAlert a) => a.resolved).toList(),
      AlertFilter.all => all,
    };
    final int critical = all
        .where((PlantAlert a) => !a.resolved && a.severity == AlertSeverity.critical)
        .length;
    final int warning = all
        .where((PlantAlert a) => !a.resolved && a.severity == AlertSeverity.warning)
        .length;
    final int resolved = all.where((PlantAlert a) => a.resolved).length;

    return Column(
      children: <Widget>[
        LiveHeader(
          title: 'Alertas',
          subtitle: 'Eventos críticos em tempo real',
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _AlertSummary(
                        label: 'Críticos',
                        value: critical,
                        color: AppColors.critical,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AlertSummary(
                        label: 'Atenção',
                        value: warning,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AlertSummary(
                        label: 'Resolvidos',
                        value: resolved,
                        color: AppColors.available,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: AlertFilter.values
                            .map(
                              (AlertFilter filter) => ChoiceChip(
                                label: Text(filter.label),
                                selected: _filter == filter,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _filter == filter
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                backgroundColor: AppColors.surface,
                                selectedColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.border),
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    if (critical + warning > 0)
                      TextButton(
                        onPressed: () => _confirmResolveAll(context, plant),
                        child: const Text('Resolver todos'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  EmptyState(
                    icon: Icons.verified_outlined,
                    title: _filter == AlertFilter.active
                        ? 'Nenhum alerta ativo'
                        : 'Nada por aqui',
                    message: _filter == AlertFilter.active
                        ? 'A planta está operando dentro dos parâmetros.'
                        : 'Nenhum registro para este filtro.',
                  )
                else
                  ...visible.map(
                    (PlantAlert alert) => AlertRow(
                      alert: alert,
                      onResolve: () => plant.resolveAlert(alert.id),
                      onTap: alert.toolId == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ToolDetailsPage(toolId: alert.toolId!),
                                ),
                              ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmResolveAll(
    BuildContext context,
    PlantController plant,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Resolver todos os alertas?', style: AppText.cardTitle),
        content: const Text(
          'Os alertas serão arquivados como tratados. Novos eventos continuarão '
          'sendo gerados pelas antenas.',
          style: AppText.caption,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) plant.resolveAllAlerts();
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.label),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: AppText.metric.copyWith(fontSize: 24, color: color),
          ),
        ],
      ),
    );
  }
}
