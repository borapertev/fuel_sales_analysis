import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdaSalesChart extends StatefulWidget {
  final Map<String, double> adaSales;
  final Map<String, double> adaSalesMoney;

  const AdaSalesChart({
    super.key,
    required this.adaSales,
    required this.adaSalesMoney,
  });

  @override
  State<AdaSalesChart> createState() => _AdaSalesChartState();
}

class _AdaSalesChartState extends State<AdaSalesChart> {
  bool showLiters = true;  // true: Litre, false: TL

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle butonu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Litre'),
              selected: showLiters,
              onSelected: (value) => setState(() => showLiters = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Tutar (₺)'),
              selected: !showLiters,
              onSelected: (value) => setState(() => showLiters = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Grafik
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (showLiters ? widget.adaSales : widget.adaSalesMoney)
                  .values
                  .reduce((a, b) => a > b ? a : b) * 1.2,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Ada ${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: (showLiters ? widget.adaSales : widget.adaSalesMoney)
                  .entries
                  .map((e) {
                int index = int.parse(e.key) - 1;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: Colors.blue.shade300,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: e.value,
                        color: Colors.transparent,
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(
                          0,
                          e.value,
                          Colors.transparent,
                          BorderSide.none,
                        ),
                      ],
                    ),
                  ],
                  barsSpace: 4,
                  showingTooltipIndicators: [0],
                );
              }).toList(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      showLiters
                          ? '${rod.toY.toStringAsFixed(1)} Lt'
                          : '₺${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topCenter,
                      labelResolver: (line) => '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 