import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import 'report_detail_screen.dart';
import 'create_report_screen.dart';

class ReportListScreen extends StatefulWidget {
  final String? userId;
  final bool isAdminView;

  const ReportListScreen({
    Key? key,
    this.userId,
    this.isAdminView = false,
  }) : super(key: key);

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  late ReportService _reportService;

  @override
  void initState() {
    super.initState();
    _reportService = Provider.of<ReportService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String?>(
        future: Future.value(
          Provider.of<AuthService>(context, listen: false).currentUser?.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = snapshot.data!;

          return StreamBuilder<List<ReportModel>>(
            stream: _getReportsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data!;
              if (reports.isEmpty) {
                return const Center(child: Text('Henüz rapor oluşturulmamış'));
              }

              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(report.title),
                      subtitle: Text(
                        '${AppConstants.reportTypeLabels[report.type] ?? report.type}\n'
                        'Oluşturulma: ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                      ),
                      trailing: Text(
                        '%${(report.completionRate * 100).toStringAsFixed(1)}',
                        style: TextStyle(
                          color: report.completionRate >= 0.7
                              ? Colors.green
                              : report.completionRate >= 0.3
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailScreen(
                              reportId: report.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateReportScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Stream<List<ReportModel>> _getReportsStream() {
    if (widget.isAdminView) {
      return _reportService.getAllReportsStream();
    } else if (widget.userId != null) {
      return _reportService.getReportsByUser(widget.userId!);
    } else {
      return _reportService.getAllReportsStream();
    }
  }
} 