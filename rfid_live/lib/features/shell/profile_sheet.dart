import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/antenna.dart';
import '../../data/models/app_user.dart';
import '../../data/models/zone.dart';
import '../../state/auth_controller.dart';
import '../../state/plant_controller.dart';

/// Painel de perfil, status das antenas e ajustes do modo ao vivo.
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
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
                        Text(user.email, style: AppText.codeMono),
                        const SizedBox(height: 6),
                        InfoPill(
                          label: user.role,
                          color: AppColors.primary,
                          icon: Icons.badge_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('MODO AO VIVO (RFID)', style: AppText.labelStrong),
                  ),
                  Switch(
                    value: plant.liveEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (bool value) => plant.setLiveEnabled(value),
                  ),
                ],
              ),
              Text(
                plant.liveEnabled
                    ? 'Leituras das antenas chegam a cada ${PlantController.tickInterval.inSeconds}s.'
                    : 'Simulação pausada — os dados permanecem congelados.',
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              Text('ANTENAS DA PLANTA', style: AppText.labelStrong),
              const SizedBox(height: 10),
              ...plant.antennas.map(
                (Antenna antenna) => _AntennaRow(antenna: antenna),
              ),
              const SizedBox(height: 8),
              Text(
                'Última sincronização: ${Fmt.clock(plant.lastSync)}',
                style: AppText.codeMono,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  final NavigatorState navigator = Navigator.of(context);
                  await context.read<AuthController>().signOut();
                  navigator.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.missing,
                  side: BorderSide(color: AppColors.missing.withValues(alpha: 0.4)),
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
        ? AppColors.warning
        : (antenna.online ? AppColors.available : AppColors.missing);
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
          Text('${antenna.readsToday} leituras', style: AppText.codeMono),
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
              style: AppText.codeMono.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
