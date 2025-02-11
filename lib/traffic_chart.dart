import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show min, max;

class TrafficChart extends StatelessWidget {
  final Map<String, int> hourlyTraffic;

  const TrafficChart({
    super.key,
    required this.hourlyTraffic,
  });

  @override
  Widget build(BuildContext context) {
    final spots = hourlyTraffic.entries.map((e) {
      // Saat değerini double'a çevir (örn: "8:30" -> 8.5)
      final timeParts = e.key.split(':');
      final hour = double.parse(timeParts[0]);
      final minute = double.parse(timeParts[1]);
      final timeValue = hour + (minute / 60);
      
      return FlSpot(timeValue, e.value.toDouble());
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    // Min ve max saatleri bul
    final minHour = spots.map((e) => e.x).reduce(min);
    final maxHour = spots.map((e) => e.x).reduce(max);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,  // Y ekseni grid aralığı
          verticalInterval: 0.5,  // X ekseni grid aralığı (30 dakika)
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 0.5 == 0 && value >= minHour && value <= maxHour) {
                  final hour = value.floor();
                  final minute = ((value % 1) * 60).round();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 35,
              interval: 0.5,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final hour = spot.x.floor();
                final minute = ((spot.x % 1) * 60).round();
                return LineTooltipItem(
                  'Saat: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}\n',
                  const TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: 'Araç Sayısı: ${spot.y.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        minX: minHour,
        maxX: maxHour,
        minY: 0,
        maxY: spots.map((e) => e.y).reduce(max) * 1.2,
      ),
    );
  }
} 