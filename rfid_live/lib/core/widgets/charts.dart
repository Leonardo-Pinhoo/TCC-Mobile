import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Linha "rótulo / barra proporcional / valor" da distribuição de status.
class DistributionRow extends StatelessWidget {
  const DistributionRow({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double ratio = total == 0 ? 0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double animated, _) {
                return LinearProgressIndicator(
                  value: animated,
                  minHeight: 3,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Anel de progresso com valor central (indicadores de BI).
class MetricRing extends StatelessWidget {
  const MetricRing({
    super.key,
    required this.ratio,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
    this.size = 108,
  });

  final double ratio;
  final String label;
  final String value;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double animated, _) {
          return CustomPaint(
            painter: _RingPainter(ratio: animated, color: color),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      child: Text(
                        label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppText.label.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 9;
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(stroke / 2 + 1);

    final Paint track = Paint()
      ..color = AppColors.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final Paint progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * ratio, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.color != color;
}

/// Histograma de movimentações por hora do dia.
class HourlyBarChart extends StatelessWidget {
  const HourlyBarChart({
    super.key,
    required this.values,
    this.color = AppColors.primary,
    this.height = 120,
  });

  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final int maxValue =
        values.isEmpty ? 0 : values.reduce((int a, int b) => a > b ? a : b);
    final int nowHour = DateTime.now().hour;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(values.length, (int hour) {
          final int value = values[hour];
          final double ratio = maxValue == 0 ? 0 : value / maxValue;
          final bool current = hour == nowHour;
          return Expanded(
            child: Tooltip(
              message: '${hour.toString().padLeft(2, '0')}h · $value mov.',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double animated, _) {
                        return Container(
                          height: math.max(3, animated * (height - 22)),
                          decoration: BoxDecoration(
                            color: value == 0
                                ? AppColors.surfaceAlt
                                : color.withValues(alpha: current ? 1 : 0.65),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    if (hour % 6 == 0)
                      Text(
                        hour.toString().padLeft(2, '0'),
                        style: AppText.label.copyWith(fontSize: 8),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Barra horizontal usada nos rankings de utilização.
class RankingBar extends StatelessWidget {
  const RankingBar({
    super.key,
    required this.label,
    required this.caption,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final String caption;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double ratio = maxValue == 0 ? 0 : value / maxValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: AppText.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('$value', style: AppText.value.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Text(
                  caption,
                  style: AppText.codeMono,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
