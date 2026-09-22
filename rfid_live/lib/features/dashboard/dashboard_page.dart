import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/live_header.dart';
import '../../data/models/movement.dart';
import '../../data/models/plant_alert.dart';
import '../../data/models/tool.dart';
import '../../data/repositories/plant_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';
import '../inventory/tool_details_page.dart';
import '../shell/profile_sheet.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onSeeAlerts,
    required this.onSeeHistory,
  });

  final VoidCallback onSeeAlerts;
  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final PlantStats stats = plant.stats;
    final List<PlantAlert> alerts = plant.activeAlerts;
    final List<Movement> movements = plant.movements.take(3).toList();

    return Column(
      children: <Widget>[
        LiveHeader(
          title: 'Painel Geral',
          refreshing: plant.refreshing,
          onRefresh: plant.refresh,
          actions: <Widget>[const _ProfileButton()],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: plant.refresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: <Widget>[
                _KpiGrid(stats: stats),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Distribuição de status',
                  child: Column(
                    children: <Widget>[
                      DistributionRow(
                        label: ToolStatus.inUse.label,
                        value: stats.inUse,
                        total: stats.total,
                        color: AppColors.inUse,
                      ),
                      DistributionRow(
                        label: ToolStatus.available.label,
                        value: stats.available,
                        total: stats.total,
                        color: AppColors.available,
                      ),
                      DistributionRow(
                        label: ToolStatus.maintenance.label,
                        value: stats.maintenance,
                        total: stats.total,
                        color: AppColors.maintenance,
                      ),
                      DistributionRow(
                        label: ToolStatus.missing.label,
                        value: stats.missing,
                        total: stats.total,
                        color: AppColors.missing,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _OperationalIndicators(stats: stats),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Últimas movimentações',
                  trailing: TextButton(
                    onPressed: onSeeHistory,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ver tudo'),
                  ),
                  child: movements.isEmpty
                      ? const EmptyState(
                          icon: Icons.swap_horiz,
                          title: 'Nenhuma movimentação registrada',
                        )
                      : Column(
                          children: <Widget>[
                            for (int i = 0; i < movements.length; i++) ...<Widget>[
                              MovementRow(
                                movement: movements[i],
                                onTap: () => _openTool(context, movements[i].toolId),
                              ),
                              if (i != movements.length - 1)
                                const Divider(color: AppColors.border),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Alertas ativos',
                  trailing: CountBadge(count: alerts.length),
                  child: alerts.isEmpty
                      ? const EmptyState(
                          icon: Icons.verified_outlined,
                          title: 'Nenhum alerta ativo',
                          message: 'Todas as ferramentas estão sob controle.',
                        )
                      : Column(
                          children: <Widget>[
                            ...alerts.take(3).map(
                                  (PlantAlert alert) => AlertRow(
                                    alert: alert,
                                    dense: true,
                                    onTap: alert.toolId == null
                                        ? onSeeAlerts
                                        : () => _openTool(context, alert.toolId!),
                                  ),
                                ),
                            if (alerts.length > 3)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: onSeeAlerts,
                                  child: Text(
                                    'Ver todos os ${alerts.length} alertas',
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                _SyncFooter(lastSync: plant.lastSync, live: plant.liveEnabled),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openTool(BuildContext context, String toolId) {
    final Tool? tool = context.read<PlantController>().toolById(toolId);
    if (tool == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ToolDetailsPage(toolId: tool.id),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final String initials =
        context.select<AuthController, String>((AuthController c) => c.user?.initials ?? '?');
    return Semantics(
      label: 'Conta e status das antenas',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: () => showProfileSheet(context),
      child: Row(
        children: <Widget>[
          Text(
            'CONTA',
            style: AppText.label.copyWith(fontSize: 9),
          ),
          const SizedBox(width: 7),
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});

  final PlantStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Altura fixa em vez de proporção: o conteúdo do cartão tem altura
      // constante, então amarrá-lo à largura esticava os cartões e abria
      // um vão enorme em telas largas (tablet).
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      children: <Widget>[
        KpiCard(
          label: 'Total rastreadas',
          value: '${stats.total}',
          color: AppColors.primary,
          caption: Fmt.compactCurrency(stats.assetValue),
        ),
        KpiCard(
          label: 'Em uso agora',
          value: '${stats.inUse}',
          color: AppColors.inUse,
          caption: 'Utilização ${Fmt.percent(stats.utilizationRate)}',
        ),
        KpiCard(
          label: 'Disponíveis',
          value: '${stats.available}',
          color: AppColors.available,
          caption: 'Prontas para retirada',
        ),
        KpiCard(
          label: 'Não localizadas',
          value: '${stats.missing}',
          color: AppColors.missing,
          caption: stats.missing == 0 ? 'Cobertura total' : 'Verificar zonas',
        ),
      ],
    );
  }
}

/// Bloco de BI: utilização, visibilidade e patrimônio rastreado.
class _OperationalIndicators extends StatelessWidget {
  const _OperationalIndicators({required this.stats});

  final PlantStats stats;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Indicadores operacionais',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          MetricRing(
            ratio: stats.utilizationRate,
            value: Fmt.percent(stats.utilizationRate),
            label: 'Utilização',
            color: AppColors.inUse,
            size: 96,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _IndicatorLine(
                  label: 'Visibilidade RFID',
                  value: Fmt.percent(stats.visibilityRate),
                  color: stats.visibilityRate >= 0.9
                      ? AppColors.available
                      : AppColors.maintenance,
                ),
                _IndicatorLine(
                  label: 'Patrimônio rastreado',
                  value: Fmt.compactCurrency(stats.trackedAssetValue),
                  color: AppColors.textPrimary,
                ),
                _IndicatorLine(
                  label: 'Movimentações hoje',
                  value: '${stats.movementsToday}',
                  color: AppColors.textPrimary,
                ),
                _IndicatorLine(
                  label: 'Manutenções vencidas',
                  value: '${stats.overdueMaintenance}',
                  color: stats.overdueMaintenance == 0
                      ? AppColors.available
                      : AppColors.maintenance,
                ),
                _IndicatorLine(
                  label: 'Horas de uso hoje',
                  value: Fmt.duration(stats.usageMinutesToday),
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorLine extends StatelessWidget {
  const _IndicatorLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppText.value.copyWith(color: color, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _SyncFooter extends StatelessWidget {
  const _SyncFooter({required this.lastSync, required this.live});

  final DateTime lastSync;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        StatusDot(
          color: live ? AppColors.live : AppColors.textMuted,
          size: 6,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            live
                ? 'Middleware RFID conectado · sync ${Fmt.clock(lastSync)}'
                : 'Modo ao vivo pausado · sync ${Fmt.clock(lastSync)}',
            style: AppText.codeMono.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
