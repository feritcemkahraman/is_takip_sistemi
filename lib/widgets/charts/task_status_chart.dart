import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/task_model.dart';

class TaskStatusChart extends StatelessWidget {
  final List<TaskModel> tasks;

  const TaskStatusChart({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, int> statusCount = {};
    
    // Görev durumlarını say
    for (var task in tasks) {
      statusCount[task.status] = (statusCount[task.status] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
    ];

    int colorIndex = 0;
    statusCount.forEach((status, count) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '$status\n$count',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 0,
          startDegreeOffset: 180,
        ),
      ),
    );
  }
}
