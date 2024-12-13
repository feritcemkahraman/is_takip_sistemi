import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meeting_service.dart';
import '../services/auth_service.dart';
import '../models/meeting_model.dart';
import '../constants/app_theme.dart';
import 'create_meeting_screen.dart';
import 'meeting_detail_screen.dart';
import '../services/export_service.dart';
import '../utils/export_helper.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  String _selectedStatus = '';
  bool _showOnlyUpcoming = true;
  late final MeetingService _meetingService;
  final _exportService = ExportService();
  List<MeetingModel> _meetings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _meetingService = Provider.of<MeetingService>(context, listen: false);
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final meetings = await _meetingService.getMeetings();
      setState(() {
        _meetings = meetings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Toplantılar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportMeetings(String format) async {
    try {
      await ExportHelper.showLoadingDialog(context);
      final result = await _exportService.exportMeetings(_meetings, format);
      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat
        await ExportHelper.showExportResultDialog(context, result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dışa aktarma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantılar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/create_meeting');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<MeetingModel>>(
              stream: _showOnlyUpcoming
                  ? _meetingService.getUpcomingMeetings(currentUser.uid)
                  : _meetingService.getUserMeetings(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final meetings = snapshot.data ?? [];
                final filteredMeetings = _selectedStatus.isEmpty
                    ? meetings
                    : meetings
                        .where((m) => m.status == _selectedStatus)
                        .toList();

                if (filteredMeetings.isEmpty) {
                  return const Center(
                    child: Text('Toplantı bulunamadı'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredMeetings.length,
                  itemBuilder: (context, index) {
                    final meeting = filteredMeetings[index];
                    return _buildMeetingCard(meeting);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus.isEmpty ? null : _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Durum',
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tümü'),
                ),
                DropdownMenuItem(
                  value: MeetingModel.statusScheduled,
                  child: Text(MeetingModel.getStatusTitle(MeetingModel.statusScheduled)),
                ),
                DropdownMenuItem(
                  value: MeetingModel.statusOngoing,
                  child: Text(MeetingModel.getStatusTitle(MeetingModel.statusOngoing)),
                ),
                DropdownMenuItem(
                  value: MeetingModel.statusCompleted,
                  child: Text(MeetingModel.getStatusTitle(MeetingModel.statusCompleted)),
                ),
                DropdownMenuItem(
                  value: MeetingModel.statusCancelled,
                  child: Text(MeetingModel.getStatusTitle(MeetingModel.statusCancelled)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value ?? '');
              },
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Yaklaşan'),
            selected: _showOnlyUpcoming,
            onSelected: (value) {
              setState(() => _showOnlyUpcoming = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting) {
    final statusColor = MeetingModel.getStatusColor(meeting.status);
    final now = DateTime.now();
    final isUpcoming = meeting.startTime.isAfter(now);
    final isToday = meeting.startTime.day == now.day &&
        meeting.startTime.month == now.month &&
        meeting.startTime.year == now.year;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeetingDetailScreen(meeting: meeting),
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
                      meeting.title,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      MeetingModel.getStatusTitle(meeting.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    meeting.isOnline ? Icons.videocam : Icons.location_on,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.isOnline
                          ? MeetingModel.getPlatformTitle(meeting.meetingPlatform!)
                          : meeting.location,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isToday
                        ? '${meeting.startTime.hour}:${meeting.startTime.minute.toString().padLeft(2, '0')} - ${meeting.endTime.hour}:${meeting.endTime.minute.toString().padLeft(2, '0')}'
                        : '${meeting.startTime.day}/${meeting.startTime.month} ${meeting.startTime.hour}:${meeting.startTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUpcoming ? Colors.blue : Colors.grey,
                      fontWeight: isUpcoming ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: meeting.departments.map((department) {
                  return Chip(
                    label: Text(
                      department,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
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
              onTap: () => _exportMeetings('pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel olarak dışa aktar'),
              onTap: () => _exportMeetings('excel'),
            ),
          ],
        ),
      ),
    );
  }
}