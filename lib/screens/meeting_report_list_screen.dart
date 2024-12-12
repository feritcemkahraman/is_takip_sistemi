import 'package:flutter/material.dart';
import '../models/meeting_report_model.dart';
import '../services/meeting_report_service.dart';
import '../utils/auth_helper.dart';
import '../constants/app_theme.dart';

class MeetingReportListScreen extends StatefulWidget {
  const MeetingReportListScreen({super.key});

  @override
  State<MeetingReportListScreen> createState() => _MeetingReportListScreenState();
}

class _MeetingReportListScreenState extends State<MeetingReportListScreen> {
  final MeetingReportService _reportService = MeetingReportService();
  late Future<List<MeetingReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final currentUser = await AuthHelper.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _reportsFuture = _reportService.getUserReports(currentUser.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantı Raporları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<MeetingReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Text('Henüz rapor bulunmuyor'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  child: ListTile(
                    title: Text(report.title),
                    subtitle: Text(
                      '${report.startDate.day}/${report.startDate.month}/${report.startDate.year} - '
                      '${report.endDate.day}/${report.endDate.month}/${report.endDate.year}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () async {
                            final result = await showDialog<List<String>>(
                              context: context,
                              builder: (context) => ShareReportDialog(
                                reportId: report.id,
                                currentSharedWith: report.sharedWith,
                              ),
                            );

                            if (result != null) {
                              await _reportService.shareReport(report.id, result);
                              _loadReports();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Raporu Sil'),
                                content: const Text(
                                  'Bu raporu silmek istediğinizden emin misiniz?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await _reportService.deleteReport(report.id);
                              _loadReports();
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/meeting_report_detail',
                        arguments: report.id,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_meeting_report').then((_) {
            _loadReports();
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ShareReportDialog extends StatefulWidget {
  final String reportId;
  final List<String> currentSharedWith;

  const ShareReportDialog({
    Key? key,
    required this.reportId,
    required this.currentSharedWith,
  }) : super(key: key);

  @override
  State<ShareReportDialog> createState() => _ShareReportDialogState();
}

class _ShareReportDialogState extends State<ShareReportDialog> {
  final _userIdController = TextEditingController();
  final List<String> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    _selectedUsers.addAll(widget.currentSharedWith);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raporu Paylaş'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _selectedUsers.map((userId) {
              return Chip(
                label: Text(userId),
                onDeleted: () {
                  setState(() {
                    _selectedUsers.remove(userId);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            final userId = _userIdController.text.trim();
            if (userId.isNotEmpty && !_selectedUsers.contains(userId)) {
              setState(() {
                _selectedUsers.add(userId);
                _userIdController.clear();
              });
            }
          },
          child: const Text('Ekle'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedUsers),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
} 