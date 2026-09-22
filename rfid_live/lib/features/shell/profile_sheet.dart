import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/antenna.dart';
import '../../data/models/app_user.dart';
import '../../data/models/zone.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';
import '../../state/theme_controller.dart';

/// Painel de perfil, status das antenas e ajustes do modo ao vivo.
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    isScrollControlled: true,
    builder: (BuildContext context) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final PlantController plant = context.watch<PlantController>();
    final AppUser user = auth.user ??
        const AppUser(name: 'Operador', email: 'operador@empresa.com.br');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.colors.primary.withValues(alpha: 0.18),
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(user.name, style: AppText.cardTitle),
                        const SizedBox(height: 3),
                        Text(user.email, style: context.texts.code),
                        const SizedBox(height: 6),
                        InfoPill(
                          label: user.role,
                          color: context.colors.primary,
                          icon: Icons.badge_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: context.colors.border),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('MODO AO VIVO (RFID)', style: context.texts.labelStrong),
                  ),
                  Switch(
                    value: plant.liveEnabled,
                    activeThumbColor: context.colors.primary,
                    onChanged: (bool value) => plant.setLiveEnabled(value),
                  ),
                ],
              ),
              Text(
                plant.liveEnabled
                    ? 'Leituras das antenas chegam a cada ${PlantController.tickInterval.inSeconds}s.'
                    : 'Simulação pausada — os dados permanecem congelados.',
                style: context.texts.caption.copyWith(color: context.colors.textMuted),
              ),
              const SizedBox(height: 18),
              Text('APARÊNCIA', style: context.texts.labelStrong),
              const SizedBox(height: 10),
              const _ThemeModePicker(),
              const SizedBox(height: 18),
              Text('ANTENAS DA PLANTA', style: context.texts.labelStrong),
              const SizedBox(height: 10),
              ...plant.antennas.map(
                (Antenna antenna) => _AntennaRow(antenna: antenna),
              ),
              const SizedBox(height: 8),
              Text(
                'Última sincronização: ${Fmt.clock(plant.lastSync)}',
                style: context.texts.code,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  final NavigatorState navigator = Navigator.of(context);
                  await context.read<AuthController>().signOut();
                  navigator.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.missing,
                  side: BorderSide(color: context.colors.missing.withValues(alpha: 0.4)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AntennaRow extends StatelessWidget {
  const _AntennaRow({required this.antenna});

  final Antenna antenna;

  @override
  Widget build(BuildContext context) {
    final Color color = antenna.lowBattery
        ? context.colors.warning
        : (antenna.online ? context.colors.available : context.colors.missing);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          StatusDot(color: color, size: 7),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${antenna.name} · ${zoneById(antenna.zoneId).name}',
              style: AppText.value,
            ),
          ),
          Text('${antenna.readsToday} leituras', style: context.texts.code),
          const SizedBox(width: 10),
          Icon(
            antenna.battery <= 20
                ? Icons.battery_alert_outlined
                : Icons.battery_full_outlined,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 3),
          SizedBox(
            width: 34,
            child: Text(
              '${antenna.battery}%',
              textAlign: TextAlign.right,
              style: context.texts.code.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Escolha entre seguir o sistema, claro ou escuro.
class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  static const Map<ThemeMode, String> _labels = <ThemeMode, String>{
    ThemeMode.system: 'Sistema',
    ThemeMode.light: 'Claro',
    ThemeMode.dark: 'Escuro',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = context.watch<ThemeController>();
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        segments: _labels.entries
            .map(
              (MapEntry<ThemeMode, String> entry) => ButtonSegment<ThemeMode>(
                value: entry.key,
                label: Text(entry.value,
                    style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        selected: <ThemeMode>{theme.mode},
        showSelectedIcon: false,
        onSelectionChanged: (Set<ThemeMode> selection) =>
            theme.setMode(selection.first),
      ),
    );
  }
}
