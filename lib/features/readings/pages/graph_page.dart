import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../reading.dart';
import '../readings_cubit.dart';

/// Screen B — consumption chart. Plots either per-day usage or total units per
/// period across the readings (x = date, y = units).
class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  bool _perDay = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: BlocBuilder<ReadingsCubit, ReadingsState>(
        builder: (context, state) {
          // Only readings with a computed value (i.e. not the baseline) chart.
          final points =
              state.computed.where((c) => c.unitsUsed != null).toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(perDay: _perDay, onToggle: (v) => setState(() => _perDay = v)),
              if (points.isEmpty)
                const _EmptyGraph()
              else ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ChartCard(points: points, perDay: _perDay),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _Legend(summary: state.summary, perDay: _perDay),
                ),
                const SizedBox(height: 28),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.perDay, required this.onToggle});
  final bool perDay;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return TealHeader(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consumption',
              style: AppType.displayLg(AppColors.paper).copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text('How your usage moves across readings',
              style: AppType.body(AppColors.paper.withAlpha(0xCC), size: 13)),
          const SizedBox(height: 16),
          _Toggle(perDay: perDay, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.perDay, required this.onToggle});
  final bool perDay;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(0x14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('Per day', perDay, () => onToggle(true)),
          _seg('Per period', !perDay, () => onToggle(false)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.copper : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppType.label(active ? AppColors.ink : AppColors.paper, size: 12.5),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.points, required this.perDay});
  final List<ComputedReading> points;
  final bool perDay;

  double _y(ComputedReading c) =>
      perDay ? (c.perDay ?? 0) : (c.unitsUsed ?? 0).toDouble();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final values = points.map(_y).toList();
    final dataMax = values.fold<double>(0, math.max);
    final dataMin = values.fold<double>(0, math.min);
    final maxY = dataMax <= 0 ? 10.0 : (dataMax * 1.25).ceilToDouble();
    final minY = dataMin < 0 ? (dataMin * 1.2).floorToDouble() : 0.0;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(perDay ? 'Units per day' : 'Units per period',
              style: AppType.title(p.primaryText, size: 16)),
          const SizedBox(height: 4),
          Text(
            perDay
                ? 'Average daily usage between each pair of readings'
                : 'Total units used in each period between readings',
            style: AppType.caption(p.secondaryText, size: 11.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: minY,
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.ink,
                    getTooltipItems: (spots) => spots.map((s) {
                      final c = points[s.x.toInt()];
                      return LineTooltipItem(
                        '${Fmt.dateShort(c.reading.date)}\n',
                        AppType.label(AppColors.paper, size: 12),
                        children: [
                          TextSpan(
                            text: perDay
                                ? '${Fmt.perDay(c.perDay!)} / day'
                                : '${c.unitsUsed} units',
                            style: AppType.mono(AppColors.copper, size: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        Fmt.perDay(value),
                        style: AppType.caption(p.secondaryText, size: 9.5),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        // Thin out labels when there are many points.
                        final step = (points.length / 5).ceil();
                        if (points.length > 6 &&
                            i % step != 0 &&
                            i != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(Fmt.dateShort(points[i].reading.date),
                              style: AppType.caption(p.secondaryText, size: 9.5)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: p.secondaryText.withAlpha(0x1A),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: false,
                    color: AppColors.petrol,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.copper,
                        strokeWidth: 2,
                        strokeColor: AppColors.petrol,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.petrol.withAlpha(0x1F),
                    ),
                    spots: [
                      for (int i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), _y(points[i])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.summary, required this.perDay});
  final dynamic summary;
  final bool perDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.copper.withAlpha(0x1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.copper.withAlpha(0x55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.copper, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Across ${summary.totalDays} days you used '
              '${Fmt.thousands(summary.totalUnitsUsed)} units — about '
              '${Fmt.perDay(summary.avgPerDay)} units per day on average.',
              style: AppType.body(p.primaryText, size: 13).copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGraph extends StatelessWidget {
  const _EmptyGraph();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 70, 40, 40),
      child: Column(
        children: [
          Icon(Icons.show_chart_rounded, size: 50, color: p.secondaryText),
          const SizedBox(height: 16),
          Text('Not enough data yet',
              style: AppType.title(p.primaryText, size: 17)),
          const SizedBox(height: 8),
          Text(
            'Add at least two readings to see your consumption over time.',
            textAlign: TextAlign.center,
            style: AppType.body(p.secondaryText, size: 13),
          ),
        ],
      ),
    );
  }
}
