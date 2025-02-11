import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentChart extends StatefulWidget {
  final Map<String, double> paymentTypes;

  const PaymentChart({
    super.key,
    required this.paymentTypes,
  });

  @override
  State<PaymentChart> createState() => _PaymentChartState();
}

class _PaymentChartState extends State<PaymentChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = widget.paymentTypes.entries.toList();
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: List.generate(entries.length, (index) {
                final isTouched = index == touchedIndex;
                final fontSize = isTouched ? 20.0 : 14.0;
                final radius = isTouched ? 110.0 : 100.0;
                final percentage = (entries[index].value / total * 100).toStringAsFixed(1);

                final colors = [
                  colorScheme.primary,
                  colorScheme.secondary,
                  colorScheme.tertiary,
                  colorScheme.error,
                ];

                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: entries[index].value,
                  title: isTouched
                      ? '${entries[index].key}\n$percentage%'
                      : percentage + '%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                );
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 150),
            swapAnimationCurve: Curves.easeInOutQuad,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final paymentType = entry.value.key;
              final amount = entry.value.value;
              final percentage = (amount / total * 100).toStringAsFixed(1);
              final colors = [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                colorScheme.error,
              ];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paymentType,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${amount.toStringAsFixed(0)}₺ ($percentage%)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
} 