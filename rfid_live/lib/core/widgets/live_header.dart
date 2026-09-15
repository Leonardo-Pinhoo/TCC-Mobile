import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_widgets.dart';

/// Relógio que se atualiza a cada segundo, isolado para não reconstruir a tela.
class LiveClock extends StatefulWidget {
  const LiveClock({super.key, this.style});

  final TextStyle? style;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      Fmt.clock(_now),
      style: widget.style ??
          const TextStyle(
            fontFamily: AppText.mono,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
    );
  }
}

/// Cabeçalho padrão das telas internas: selo ao vivo, título, relógio e
/// botão de atualização manual das leituras.
class LiveHeader extends StatelessWidget {
  const LiveHeader({
    super.key,
    required this.title,
    required this.onRefresh,
    this.refreshing = false,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final Future<void> Function() onRefresh;
  final bool refreshing;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundTop,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const LiveDot(),
              const SizedBox(width: 6),
              const Text(
                'RFID LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: AppColors.live,
                ),
              ),
              const Spacer(),
              ...actions,
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppText.title),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const LiveClock(),
              const SizedBox(width: 10),
              _RefreshButton(onRefresh: onRefresh, refreshing: refreshing),
            ],
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onRefresh, required this.refreshing});

  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: refreshing ? null : () => onRefresh(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 13,
                height: 13,
                child: refreshing
                    ? const CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Colors.white,
                      )
                    : const Icon(Icons.refresh, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text(
                'Atualizar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
