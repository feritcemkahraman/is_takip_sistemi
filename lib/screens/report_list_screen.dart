import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/report_model.dart';
import '../constants/app_theme.dart';
import 'create_report_screen.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final reportService = Provider.of<ReportService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: reportService.getReports(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Text('Henüz rapor oluşturulmamış'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(report: report);
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ReportModel.getTitle(report.type),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tarih Aralığı: ${report.startDate.day}/${report.startDate.month}/${report.startDate.year} - ${report.endDate.day}/${report.endDate.month}/${report.endDate.year}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Oluşturulma: ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStat(
                    'Toplam',
                    report.getTotalTasks().toString(),
                    Icons.assignment,
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    'Tamamlanan',
                    report.getCompletedTasks().toString(),
                    Icons.check_circle,
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    'Oran',
                    '%${report.getCompletionRate().toStringAsFixed(1)}',
                    Icons.pie_chart,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 