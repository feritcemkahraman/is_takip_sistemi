import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';
import '../widgets/meeting_minutes_section.dart';
import '../widgets/meeting_decisions_section.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({
    Key? key,
    required this.meetingId,
  }) : super(key: key);

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  final MeetingService _meetingService = MeetingService();
  late Future<MeetingModel> _meetingFuture;

  @override
  void initState() {
    super.initState();
    _meetingFuture = _meetingService.getMeeting(widget.meetingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantı Detayları'),
      ),
      body: FutureBuilder<MeetingModel>(
        future: _meetingFuture,
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
              child: Text('Toplantı bulunamadı'),
            );
          }

          final meeting = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMeetingHeader(meeting),
                const SizedBox(height: 24),
                _buildMeetingInfo(meeting),
                const SizedBox(height: 24),
                _buildParticipants(meeting),
                const SizedBox(height: 24),
                _buildAgenda(meeting),
                const SizedBox(height: 24),
                MeetingMinutesSection(
                  meeting: meeting,
                  onMinutesUpdated: () {
                    setState(() {
                      _meetingFuture = _meetingService.getMeeting(widget.meetingId);
                    });
                  },
                ),
                const SizedBox(height: 24),
                MeetingDecisionsSection(
                  meeting: meeting,
                  onDecisionsUpdated: () {
                    setState(() {
                      _meetingFuture = _meetingService.getMeeting(widget.meetingId);
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingHeader(MeetingModel meeting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meeting.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          meeting.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildMeetingInfo(MeetingModel meeting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toplantı Bilgileri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Başlangıç',
              '${meeting.startTime.day}/${meeting.startTime.month}/${meeting.startTime.year} ${meeting.startTime.hour}:${meeting.startTime.minute}',
            ),
            _buildInfoRow(
              'Bitiş',
              '${meeting.endTime.day}/${meeting.endTime.month}/${meeting.endTime.year} ${meeting.endTime.hour}:${meeting.endTime.minute}',
            ),
            _buildInfoRow(
              'Durum',
              meeting.status,
            ),
            if (meeting.isOnline) ...[
              _buildInfoRow('Platform', meeting.meetingPlatform ?? ''),
              _buildInfoRow('Bağlantı', meeting.meetingLink ?? ''),
            ] else
              _buildInfoRow('Konum', meeting.location),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildParticipants(MeetingModel meeting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Katılımcılar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meeting.participants.length,
              itemBuilder: (context, index) {
                final participant = meeting.participants[index];
                return ListTile(
                  title: Text(participant.name),
                  subtitle: Text(participant.rsvpStatus),
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgenda(MeetingModel meeting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gündem',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meeting.agenda.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(meeting.agenda[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 