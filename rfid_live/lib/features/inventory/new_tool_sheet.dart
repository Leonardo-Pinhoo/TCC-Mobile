import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tool.dart';
import '../../data/models/zone.dart';
import '../../data/repositories/plant_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';
import '../auth/widgets/auth_scaffold.dart';

/// Formulário de cadastro de uma nova ferramenta etiquetada.
Future<void> showNewToolSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (BuildContext context) => const _NewToolSheet(),
  );
}

class _NewToolSheet extends StatefulWidget {
  const _NewToolSheet();

  @override
  State<_NewToolSheet> createState() => _NewToolSheetState();
}

class _NewToolSheetState extends State<_NewToolSheet> {
  static const List<String> _categories = <String>[
    'Manual',
    'Elétrica',
    'Pneumática',
    'Medição',
    'Corte',
    'Segurança',
  ];
  static const List<String> _criticalities = <String>['Baixa', 'Média', 'Alta'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _tag = TextEditingController();
  final TextEditingController _value = TextEditingController();
  String _category = _categories.first;
  String _zoneId = 'ZN-005';
  String _criticality = 'Média';

  @override
  void initState() {
    super.initState();
    _tag.text = _freshTag();
  }

  /// Sorteia um EPC que ainda não esteja vinculado a nenhuma ferramenta.
  String _freshTag() {
    final PlantController plant = context.read<PlantController>();
    String tag = _generateTag();
    for (int attempt = 0; attempt < 20 && plant.toolByTag(tag) != null; attempt++) {
      tag = _generateTag();
    }
    return tag;
  }

  /// O EPC identifica a etiqueta na planta: precisa ser hexadecimal, estar no
  /// formato lido pelas antenas e não pode repetir outra ferramenta.
  String? _validateTag(String? value) {
    final String tag = (value ?? '').trim().toUpperCase();
    if (tag.isEmpty) return 'Informe o EPC da etiqueta';
    if (!PlantRepository.isValidEpc(tag)) {
      return 'Formato inválido. Use E2:XX:XX:XX (hexadecimal)';
    }
    final Tool? duplicate = context.read<PlantController>().toolByTag(tag);
    if (duplicate != null) {
      return 'EPC já vinculado a ${duplicate.id} — ${duplicate.name}';
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _tag.dispose();
    _value.dispose();
    super.dispose();
  }

  /// Gera um EPC no mesmo formato lido pelas antenas (E2:XX:XX:XX).
  String _generateTag() {
    final Random random = Random();
    String hex() => random.nextInt(256).toRadixString(16).toUpperCase().padLeft(2, '0');
    return 'E2:${hex()}:${hex()}:${hex()}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final PlantController plant = context.read<PlantController>();
    final String user = context.read<AuthController>().user?.name ?? 'Operador';

    // Capturados antes do pop: depois de fechar a folha este contexto já não
    // pode ser usado para localizar o ScaffoldMessenger.
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final Tool tool;
    try {
      tool = plant.addTool(
        name: _name.text.trim(),
        tag: _tag.text.trim().toUpperCase(),
        zoneId: _zoneId,
        category: _category,
        assetValue: double.tryParse(_value.text.replaceAll(',', '.')) ?? 0,
        criticality: _criticality,
        user: user,
      );
    } on PlantException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${tool.name} cadastrada como ${tool.id}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('CADASTRAR FERRAMENTA', style: AppText.labelStrong),
                const SizedBox(height: 4),
                Text(
                  'A etiqueta passa a ser rastreada na próxima varredura.',
                  style: AppText.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Descrição',
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ex.: Chave de Fenda Isolada 6mm',
                    ),
                    validator: (String? value) =>
                        (value ?? '').trim().length < 3 ? 'Informe a descrição' : null,
                  ),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'EPC da etiqueta',
                  child: TextFormField(
                    controller: _tag,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: AppText.mono,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: InputDecoration(
                      hintText: 'E2:00:1A:B3',
                      suffixIcon: IconButton(
                        tooltip: 'Gerar novo EPC',
                        onPressed: () =>
                            setState(() => _tag.text = _freshTag()),
                        icon: const Icon(
                          Icons.autorenew,
                          size: 19,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    validator: _validateTag,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: LabeledField(
                        label: 'Categoria',
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceAlt,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          items: _categories
                              .map((String c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (String? v) =>
                              setState(() => _category = v ?? _categories.first),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(
                        label: 'Zona inicial',
                        child: DropdownButtonFormField<String>(
                          initialValue: _zoneId,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceAlt,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          items: kZones
                              .map((Zone z) => DropdownMenuItem<String>(
                                    value: z.id,
                                    child: Text(z.name),
                                  ))
                              .toList(),
                          onChanged: (String? v) =>
                              setState(() => _zoneId = v ?? 'ZN-005'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Valor do ativo (R\$)',
                  child: TextFormField(
                    controller: _value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(hintText: '0,00'),
                    validator: (String? value) {
                      final double? parsed =
                          double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'Informe um valor válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('CRITICIDADE', style: AppText.label),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _criticalities
                      .map((String c) => ButtonSegment<String>(
                            value: c,
                            label: Text(c, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  selected: <String>{_criticality},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<String> selection) =>
                      setState(() => _criticality = selection.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) =>
                          states.contains(WidgetState.selected)
                              ? AppColors.primary
                              : AppColors.surfaceInput,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) =>
                          states.contains(WidgetState.selected)
                              ? Colors.white
                              : AppColors.textSecondary,
                    ),
                    side: const WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Cadastrar ferramenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
