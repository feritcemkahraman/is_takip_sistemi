import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';

class ReportDetailScreen extends StatelessWidget {
  final ReportModel report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildStatusDistributionChart(),
            const SizedBox(height: 24),
            _buildPriorityDistributionChart(),
            if (report.type == ReportModel.typeDepartment) ...[
              const SizedBox(height: 24),
              _buildDepartmentPerformanceChart(),
            ],
            if (report.type == ReportModel.typeUser) ...[
              const SizedBox(height: 24),
              _buildUserTaskCompletionChart(),
            ],
            const SizedBox(height: 24),
            _buildTimelineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ReportModel.getTitle(report.type),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarih Aralığı: ${report.startDate.day}/${report.startDate.month}/${report.startDate.year} - ${report.endDate.day}/${report.endDate.month}/${report.endDate.year}',
            ),
            const SizedBox(height: 4),
            Text(
              'Oluşturulma: ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Toplam Görev',
          report.getTotalTasks().toString(),
          Icons.assignment,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Tamamlanan',
          report.getCompletedTasks().toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildSummaryCard(
          'Geciken',
          report.getOverdueTasks().toString(),
          Icons.warning,
          Colors.red,
        ),
        _buildSummaryCard(
          'Tamamlanma Oranı',
          '%${report.getCompletionRate().toStringAsFixed(1)}',
          Icons.pie_chart,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistributionChart() {
    final data = report.getTaskStatusDistribution();
    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Durum Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((entry) {
                    final percent = (entry.value / total) * 100;
                    final status = AppConstants.statusLabels[entry.key] ?? entry.key;
                    final color = AppConstants.statusColors[entry.key] ?? Colors.grey;
                    
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '$status\n%${percent.toStringAsFixed(1)}',
                      color: color,
                      radius: 100,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDistributionChart() {
    final data = report.getTaskPriorityDistribution();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Öncelik Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.values.fold<int>(0, max) * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final priorities = data.keys.toList();
                          if (value >= 0 && value < priorities.length) {
                            final priority = priorities[value.toInt()];
                            return Text(
                              AppConstants.priorityLabels[priority] ?? priority,
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.entries.map((entry) {
                    return BarChartGroupData(
                      x: data.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: AppConstants.priorityColors[entry.key],
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentPerformanceChart() {
    final data = report.getDepartmentPerformance();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Departman Performansı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final departments = data.keys.toList();
                          if (value >= 0 && value < departments.length) {
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                departments[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.entries.map((entry) {
                    return BarChartGroupData(
                      x: data.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTaskCompletionChart() {
    final data = report.getUserTaskCompletion();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kullanıcı Görev Tamamlama',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data.entries.elementAt(index);
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: FutureBuilder<String>(
                    future: _getUserName(context, entry.key),
                    builder: (context, snapshot) {
                      return Text(snapshot.data ?? 'Kullanıcı');
                    },
                  ),
                  trailing: Text(
                    '${entry.value} görev',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineChart() {
    final timeline = report.getTimelineData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zaman Çizelgesi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    // Toplam görev çizgisi
                    LineChartBarData(
                      spots: timeline.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['total'].toDouble(),
                        );
                      }).toList(),
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                    // Tamamlanan görev çizgisi
                    LineChartBarData(
                      spots: timeline.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['completed'].toDouble(),
                        );
                      }).toList(),
                      color: Colors.green,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < timeline.length) {
                            final date = timeline[value.toInt()]['date'] as DateTime;
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(
                  color: Colors.blue,
                  label: 'Toplam Görev',
                ),
                SizedBox(width: 16),
                _LegendItem(
                  color: Colors.green,
                  label: 'Tamamlanan',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getUserName(BuildContext context, String userId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getUserById(userId);
      return user?.name ?? 'Kullanıcı';
    } catch (e) {
      return 'Kullanıcı';
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
} 