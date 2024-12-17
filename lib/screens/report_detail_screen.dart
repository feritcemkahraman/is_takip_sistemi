import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../utils/export_helper.dart';
import '../constants/app_constants.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  Future<void> _shareReport(BuildContext context, ReportModel report) async {
    try {
      final result = await ExportHelper.shareFile(
        report.toFile(),
        subject: 'Rapor: ${report.title}',
        text: 'Rapor detayları',
      );

      if (!result.isSuccess) {
        if (context.mounted) {
          ExportHelper.showErrorDialog(context, result.message ?? 'Paylaşım hatası');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ExportHelper.showErrorDialog(context, 'Paylaşım sırasında hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReportModel?>(
      stream: Provider.of<ReportService>(context).getReportStream(reportId),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rapor Detayı'),
            actions: [
              if (snapshot.hasData)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareReport(context, snapshot.data!),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final report = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rapor Türü: ${AppConstants.reportTypeLabels[report.type] ?? report.type}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Oluşturulma: ${_formatDate(report.createdAt)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Başlangıç: ${_formatDate(report.startDate)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bitiş: ${_formatDate(report.endDate)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'İstatistikler',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildStatisticsCard(context, report),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(BuildContext context, ReportModel report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticRow(
              context,
              'Toplam Görev',
              report.totalTasks.toString(),
            ),
            const SizedBox(height: 8),
            _buildStatisticRow(
              context,
              'Tamamlanan Görev',
              report.completedTasks.toString(),
            ),
            const SizedBox(height: 8),
            _buildStatisticRow(
              context,
              'Tamamlanma Oranı',
              '%${(report.completionRate * 100).toStringAsFixed(1)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}