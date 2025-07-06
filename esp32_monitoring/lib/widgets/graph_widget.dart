import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement_data.dart';
import 'package:intl/intl.dart';

class GraphWidget extends StatelessWidget {
  final List<MeasurementData> data;
  final String title;
  final String yAxisLabel;
  final double? Function(MeasurementData) valueSelector;
  final double minY; // Minimum Y-axis value
  final double maxY; // Maximum Y-axis value

  const GraphWidget({
    super.key,
    required this.data,
    required this.title,
    required this.yAxisLabel,
    required this.valueSelector,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: minY, // Set minimum Y-axis value
                  maxY: maxY, // Set maximum Y-axis value
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval:
                        10, // Interval for horizontal grid lines
                    verticalInterval: 1, // Interval for vertical grid lines
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey,
                      strokeWidth: 0.5,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(), // Display integer values
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final timestamp = data[index].timestamp;

                            // Format the timestamp as HH:mm
                            final formattedTime =
                                DateFormat('HH:mm').format(timestamp);

                            return Text(
                              formattedTime,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false), // Disable top titles
                    ),
                    rightTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false), // Disable right titles
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                valueSelector(entry.value) ?? 0,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
