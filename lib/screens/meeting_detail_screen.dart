import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';
import '../services/auth_service.dart';
import '../constants/app_theme.dart';
import '../widgets/file_list_widget.dart';
import '../screens/edit_meeting_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final MeetingModel meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final _noteController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onEditPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMeetingScreen(meeting: widget.meeting),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetingService = Provider.of<MeetingService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı bulunamadı')),
      );
    }

    final isOrganizer = widget.meeting.organizerId == currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantı Detayları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isOrganizer && widget.meeting.status == MeetingModel.statusScheduled)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    _onEditPressed();
                    break;
                  case 'cancel':
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Toplantıyı İptal Et'),
                        content: const Text(
                          'Bu toplantıyı iptal etmek istediğinizden emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Vazgeç'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('İptal Et'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await meetingService.updateMeetingStatus(
                        widget.meeting.id,
                        MeetingModel.statusCancelled,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Düzenle'),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('İptal Et'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 32),
            _buildDetails(),
            const Divider(height: 32),
            _buildParticipants(),
            const Divider(height: 32),
            _buildAgenda(),
            if (widget.meeting.attachments.isNotEmpty) ...[
              const Divider(height: 32),
              _buildAttachments(),
            ],
            const Divider(height: 32),
            _buildNotes(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusColor = MeetingModel.getStatusColor(widget.meeting.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.meeting.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            MeetingModel.getStatusTitle(widget.meeting.status),
            style: TextStyle(color: statusColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toplantı Detayları',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          icon: widget.meeting.isOnline ? Icons.videocam : Icons.location_on,
          title: 'Konum',
          value: widget.meeting.isOnline
              ? MeetingModel.getPlatformTitle(widget.meeting.meetingPlatform!)
              : widget.meeting.location,
        ),
        if (widget.meeting.isOnline && widget.meeting.meetingLink != null)
          _buildDetailRow(
            icon: Icons.link,
            title: 'Toplantı Linki',
            value: widget.meeting.meetingLink!,
            isLink: true,
          ),
        _buildDetailRow(
          icon: Icons.access_time,
          title: 'Başlangıç',
          value:
              '${widget.meeting.startTime.day}/${widget.meeting.startTime.month}/${widget.meeting.startTime.year} ${widget.meeting.startTime.hour}:${widget.meeting.startTime.minute.toString().padLeft(2, '0')}',
        ),
        _buildDetailRow(
          icon: Icons.access_time,
          title: 'Bitiş',
          value:
              '${widget.meeting.endTime.day}/${widget.meeting.endTime.month}/${widget.meeting.endTime.year} ${widget.meeting.endTime.hour}:${widget.meeting.endTime.minute.toString().padLeft(2, '0')}',
        ),
        if (widget.meeting.isRecurring) ...[
          const SizedBox(height: 8),
          _buildRecurrenceInfo(),
        ],
        if (widget.meeting.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.meeting.description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildRecurrenceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Tekrarlayan Toplantı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.meeting.getRecurrenceDescription(),
              style: const TextStyle(fontSize: 14),
            ),
            if (widget.meeting.parentMeetingId != null) ...[
              const SizedBox(height: 8),
              StreamBuilder<List<MeetingModel>>(
                stream: Provider.of<MeetingService>(context)
                    .getRecurringMeetings(widget.meeting.parentMeetingId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final meetings = snapshot.data!;
                  final upcomingMeetings = meetings
                      .where((m) =>
                          m.startTime.isAfter(DateTime.now()) &&
                          m.status != MeetingModel.statusCancelled)
                      .toList();

                  if (upcomingMeetings.isEmpty) {
                    return const SizedBox();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yaklaşan Toplantılar:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...upcomingMeetings.take(3).map((meeting) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            '${meeting.startTime.day}/${meeting.startTime.month} ${meeting.startTime.hour}:${meeting.startTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                      if (upcomingMeetings.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            've ${upcomingMeetings.length - 3} toplantı daha...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isLink ? Colors.blue : null,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants() {
    final authService = Provider.of<AuthService>(context);
    final meetingService = Provider.of<MeetingService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const SizedBox();
    }

    final isParticipant = widget.meeting.participants
        .any((p) => p.userId == currentUser.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Katılımcılar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isParticipant && widget.meeting.status == MeetingModel.statusScheduled)
              _buildRsvpButtons(currentUser, meetingService),
          ],
        ),
        const SizedBox(height: 16),
        _buildRsvpStats(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.meeting.participants.map((participant) {
            final rsvpStatus = participant.rsvpStatus;
            final statusColor = _getRsvpStatusColor(rsvpStatus);
            final statusText = MeetingParticipant.getStatusTitle(rsvpStatus);

            return Chip(
              avatar: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(
                  _getRsvpStatusIcon(rsvpStatus),
                  size: 16,
                  color: statusColor,
                ),
              ),
              label: Text(participant.name),
              backgroundColor: Colors.grey[200],
              deleteIcon: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                ),
              ),
              onDeleted: () {}, // Boş fonksiyon, sadece etiketi göstermek için
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRsvpStats() {
    final stats = widget.meeting.getRsvpStats();
    final total = stats.values.fold<int>(0, (sum, count) => sum + count);

    return Row(
      children: [
        _buildRsvpStatItem(
          'Katılacak',
          stats[MeetingParticipant.statusAttending] ?? 0,
          total,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildRsvpStatItem(
          'Katılmayacak',
          stats[MeetingParticipant.statusDeclined] ?? 0,
          total,
          Colors.red,
        ),
        const SizedBox(width: 16),
        _buildRsvpStatItem(
          'Yanıt Bekleyen',
          stats[MeetingParticipant.statusPending] ?? 0,
          total,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildRsvpStatItem(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '%$percentage',
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButtons(User currentUser, MeetingService meetingService) {
    final currentParticipant = widget.meeting.participants
        .firstWhere((p) => p.userId == currentUser.uid);
    final currentStatus = currentParticipant.rsvpStatus;

    return Row(
      children: [
        _buildRsvpButton(
          'Katılacağım',
          Icons.check_circle,
          Colors.green,
          currentStatus == MeetingParticipant.statusAttending,
          () => meetingService.updateRsvpStatus(
            widget.meeting.id,
            currentUser.uid,
            currentUser.displayName ?? 'İsimsiz Kullanıcı',
            MeetingParticipant.statusAttending,
          ),
        ),
        const SizedBox(width: 8),
        _buildRsvpButton(
          'Katılmayacağım',
          Icons.cancel,
          Colors.red,
          currentStatus == MeetingParticipant.statusDeclined,
          () => meetingService.updateRsvpStatus(
            widget.meeting.id,
            currentUser.uid,
            currentUser.displayName ?? 'İsimsiz Kullanıcı',
            MeetingParticipant.statusDeclined,
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : color,
        size: 16,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
    );
  }

  Color _getRsvpStatusColor(String status) {
    switch (status) {
      case MeetingParticipant.statusAttending:
        return Colors.green;
      case MeetingParticipant.statusDeclined:
        return Colors.red;
      case MeetingParticipant.statusPending:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRsvpStatusIcon(String status) {
    switch (status) {
      case MeetingParticipant.statusAttending:
        return Icons.check_circle;
      case MeetingParticipant.statusDeclined:
        return Icons.cancel;
      case MeetingParticipant.statusPending:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Widget _buildAgenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gündem Maddeleri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.meeting.agenda.isEmpty)
          const Text('Gündem maddesi bulunmuyor')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.meeting.agenda.length,
            itemBuilder: (context, index) {
              final item = widget.meeting.agenda[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(item),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ekler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FileListWidget(files: widget.meeting.attachments),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.meeting.notes.length,
          itemBuilder: (context, index) {
            final note = widget.meeting.notes[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${note.createdBy} - ${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.meeting.status != MeetingModel.statusCancelled) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Not ekle...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (_noteController.text.trim().isNotEmpty) {
                    final meetingService =
                        Provider.of<MeetingService>(context, listen: false);
                    final authService =
                        Provider.of<AuthService>(context, listen: false);
                    final currentUser = authService.currentUser;

                    if (currentUser != null) {
                      await meetingService.addMeetingNote(
                        widget.meeting.id,
                        _noteController.text.trim(),
                        currentUser.displayName ?? 'İsimsiz Kullanıcı',
                      );
                      _noteController.clear();
                    }
                  }
                },
              ),
            ),
            maxLines: 3,
          ),
        ],
      ],
    );
  }
} 