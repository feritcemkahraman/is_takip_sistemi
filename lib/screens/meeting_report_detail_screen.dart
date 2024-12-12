import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/meeting_report_model.dart';
import '../services/meeting_report_service.dart';
import '../constants/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/export_service.dart';

class MeetingReportDetailScreen extends StatefulWidget {
  final String reportId;

  const MeetingReportDetailScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  State<MeetingReportDetailScreen> createState() => _MeetingReportDetailScreenState();
}

class _MeetingReportDetailScreenState extends State<MeetingReportDetailScreen> {
  final MeetingReportService _reportService = MeetingReportService();
  late Future<MeetingReportModel> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _reportService.getReport(widget.reportId);
  }

  Widget _buildStatusDistributionChart(Map<String, int> data) {
    final pieData = data.entries.map((entry) {
      final color = entry.key == 'completed'
          ? Colors.green
          : entry.key == 'cancelled'
              ? Colors.red
              : entry.key == 'ongoing'
                  ? Colors.blue
                  : Colors.orange;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: pieData,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildParticipationChart(Map<String, double> data) {
    final barGroups = data.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key.hashCode % 100,
        barRods: [
          BarChartRodData(
            toY: entry.value * 100,
            color: AppTheme.primaryColor,
            width: 16,
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = barGroups.indexWhere((g) => g.x == value);
                  if (index >= 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data.keys.elementAt(index),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%');
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineChart(List<Map<String, dynamic>> timeline) {
    final spots = timeline.asMap().entries.map((entry) {
      final data = entry.value;
      return FlSpot(
        entry.key.toDouble(),
        (data['participantCount'] as int).toDouble(),
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < timeline.length) {
                    final date = DateTime.parse(timeline[index]['date'] as String);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<MeetingReportModel>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Rapor bulunamadı'),
            );
          }

          final report = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${report.startDate.day}/${report.startDate.month}/${report.startDate.year} - ${report.endDate.day}/${report.endDate.month}/${report.endDate.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genel İstatistikler',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Toplam Toplantı', report.getTotalMeetings()),
                        _buildStatRow('Tamamlanan Toplantı', report.getCompletedMeetings()),
                        _buildStatRow('İptal Edilen Toplantı', report.getCancelledMeetings()),
                        _buildStatRow('Toplam Karar', report.getTotalDecisions()),
                        _buildStatRow('Tamamlanan Karar', report.getCompletedDecisions()),
                        _buildStatRow('Geciken Karar', report.getOverdueDecisions()),
                        _buildStatRow(
                          'Karar Tamamlanma Oranı',
                          '${(report.getDecisionCompletionRate() * 100).toStringAsFixed(1)}%',
                        ),
                        _buildStatRow(
                          'Katılım Oranı',
                          '${(report.getMeetingAttendanceRate() * 100).toStringAsFixed(1)}%',
                        ),
                        _buildStatRow(
                          'Ortalama Toplantı Süresi',
                          '${report.getAverageMeetingDuration().toStringAsFixed(0)} dakika',
                        ),
                        _buildStatRow(
                          'Ortalama Karar Tamamlanma Süresi',
                          '${report.getAverageDecisionCompletionTime().toStringAsFixed(1)} gün',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplantı Durumu Dağılımı',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusDistributionChart(
                          report.getMeetingStatusDistribution(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departman Katılımı',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildParticipationChart(
                          report.getDepartmentParticipation(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zaman Çizelgesi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildTimelineChart(report.getTimelineData()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dışa Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF olarak dışa aktar'),
              onTap: () async {
                Navigator.pop(context);
                final exportService = Provider.of<ExportService>(
                  context,
                  listen: false,
                );
                await exportService.exportMeetingReport(widget.report, 'pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel olarak dışa aktar'),
              onTap: () async {
                Navigator.pop(context);
                final exportService = Provider.of<ExportService>(
                  context,
                  listen: false,
                );
                await exportService.exportMeetingReport(widget.report, 'excel');
              },
            ),
          ],
        ),
      ),
    );
  }
} 