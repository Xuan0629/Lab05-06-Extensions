import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'grade.dart';

class GradesChart extends StatelessWidget {
  final List<Grade> grades;

  const GradesChart({Key? key, required this.grades}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Count the frequency of each grade
    final gradeFrequency = <String, int>{};
    for (var grade in grades) {
      gradeFrequency.update(grade.grade, (value) => value + 1, ifAbsent: () => 1);
    }

    // Sort the keys and map the data to BarChartGroupData for the chart
    final sortedKeys = gradeFrequency.keys.toList()..sort();
    final barGroups = sortedKeys.asMap().map((index, key) {
      final value = gradeFrequency[key]!.toDouble();
      return MapEntry(
        index,
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              fromY: 0, // Frequency of the grade
              color: Colors.blue,
              toY: value, // The maximum value of the Y axis
              width: 20,
            ),
          ],
        ),
      );
    }).values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades Chart'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // Reserve space for titles
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedKeys.length) {
                      return Text(sortedKeys[index]);
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // if (value == 0) {
                    //   return const Text('');
                    // }
                    return Text('${value.toInt()}');
                  },
                  interval: 1, // Set the interval for the Y axis labels
                  reservedSize: 40, // Reserve space for titles
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            // add label for x & y axis if need
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            alignment: BarChartAlignment.spaceAround,
          ),
        ),
      ),
    );
  }
}