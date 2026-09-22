import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/live_header.dart';
import '../../data/models/tool.dart';
import '../../state/plant_controller.dart';
import 'new_tool_sheet.dart';
import 'tool_details_page.dart';
import 'widgets/tool_card.dart';

enum ToolSort { recent, name, zone, value }

extension _ToolSortX on ToolSort {
  String get label => switch (this) {
        ToolSort.recent => 'Leitura mais recente',
        ToolSort.name => 'Nome (A-Z)',
        ToolSort.zone => 'Zona',
        ToolSort.value => 'Maior valor',
      };
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _search = TextEditingController();
  ToolStatus? _status;
  ToolSort _sort = ToolSort.recent;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Tool> _sorted(List<Tool> tools) {
    final List<Tool> list = List<Tool>.from(tools);
    switch (_sort) {
      case ToolSort.recent:
        list.sort((Tool a, Tool b) => b.lastRead.compareTo(a.lastRead));
      case ToolSort.name:
        list.sort((Tool a, Tool b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ToolSort.zone:
        list.sort((Tool a, Tool b) =>
            (a.zoneId ?? 'ZZ').compareTo(b.zoneId ?? 'ZZ'));
      case ToolSort.value:
        list.sort((Tool a, Tool b) => b.assetValue.compareTo(a.assetValue));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final PlantController plant = context.watch<PlantController>();
    final List<Tool> tools = _sorted(
      plant.search(query: _search.text, status: _status),
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewToolSheet(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Cadastrar',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: Column(
        children: <Widget>[
          LiveHeader(
            title: 'Inventário',
            refreshing: plant.refreshing,
            onRefresh: plant.refresh,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar ferramenta, ID ou tag...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 19,
                  color: context.colors.textMuted,
                ),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: context.colors.textMuted,
                        ),
                      ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                _FilterChip(
                  label: 'Todas',
                  selected: _status == null,
                  color: context.colors.primary,
                  onTap: () => setState(() => _status = null),
                ),
                ...ToolStatus.values.map(
                  (ToolStatus status) => _FilterChip(
                    label: status.shortLabel,
                    selected: _status == status,
                    color: status.colorIn(context.colors),
                    onTap: () => setState(() => _status = status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${tools.length} de ${plant.tools.length} ferramentas',
                    style: context.texts.label,
                  ),
                ),
                PopupMenuButton<ToolSort>(
                  initialValue: _sort,
                  color: context.colors.surfaceAlt,
                  tooltip: 'Ordenar',
                  onSelected: (ToolSort value) => setState(() => _sort = value),
                  itemBuilder: (BuildContext context) => ToolSort.values
                      .map(
                        (ToolSort sort) => PopupMenuItem<ToolSort>(
                          value: sort,
                          child: Text(sort.label, style: context.texts.caption),
                        ),
                      )
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('ORDENAR', style: context.texts.label),
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: context.colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: plant.refresh,
              color: context.colors.primary,
              backgroundColor: context.colors.surface,
              child: tools.isEmpty
                  ? ListView(
                      children: <Widget>[
                        EmptyState(
                          icon: Icons.search_off,
                          title: 'Nenhuma ferramenta encontrada',
                          message:
                              'Ajuste a busca ou o filtro de status para ver resultados.',
                          action: OutlinedButton(
                            onPressed: () => setState(() {
                              _search.clear();
                              _status = null;
                            }),
                            child: const Text('Limpar filtros'),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: tools.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final Tool tool = tools[index];
                        return ToolCard(
                          tool: tool,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ToolDetailsPage(
                                toolId: tool.id,
                                toolIds: tools.map((Tool t) => t.id).toList(),
                                initialIndex: index,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color : context.colors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? color : context.colors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? context.colors.onAccent(color) : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
