import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../state/plant_controller.dart';
import '../alerts/alerts_page.dart';
import '../dashboard/dashboard_page.dart';
import '../history/history_page.dart';
import '../inventory/inventory_page.dart';
import '../map/plant_map_page.dart';

/// Casca da área autenticada: mantém as cinco abas vivas e sincronizadas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final int alerts =
        context.select<PlantController, int>((PlantController c) => c.activeAlerts.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      // O fundo do cabeçalho se estende sob a barra de status; a área segura
      // impede que ele fique atrás dos ícones do sistema.
      body: ColoredBox(
        color: AppColors.backgroundTop,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: <Widget>[
              DashboardPage(
                onSeeAlerts: () => _goTo(3),
                onSeeHistory: () => _goTo(4),
              ),
              const PlantMapPage(),
              const InventoryPage(),
              const AlertsPage(),
              const HistoryPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        alertCount: alerts,
        onChanged: _goTo,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onChanged,
    required this.alertCount,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int alertCount;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem('Painel', Icons.grid_view_outlined, Icons.grid_view_rounded),
    _NavItem('Mapa', Icons.map_outlined, Icons.map_rounded),
    _NavItem('Inventário', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('Alertas', Icons.notifications_outlined, Icons.notifications_rounded),
    _NavItem('Histórico', Icons.history_outlined, Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundTop,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List<Widget>.generate(_items.length, (int i) {
              final _NavItem item = _items[i];
              final bool active = i == index;
              final Color color =
                  active ? AppColors.primary : AppColors.textMuted;
              final String semanticLabel = i == 3 && alertCount > 0
                  ? '${item.label}, $alertCount ativos'
                  : item.label;
              return Expanded(
                child: Semantics(
                  label: semanticLabel,
                  selected: active,
                  button: true,
                  excludeSemantics: true,
                  child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Icon(
                            active ? item.activeIcon : item.icon,
                            size: 21,
                            color: color,
                          ),
                          if (i == 3 && alertCount > 0)
                            Positioned(
                              right: -9,
                              top: -6,
                              child: CountBadge(count: alertCount),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 2,
                        width: active ? 22 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
