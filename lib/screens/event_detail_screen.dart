import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

class EventDetailScreen extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Detayı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          event.type == 'task'
                              ? Icons.task
                              : event.type == 'meeting'
                                  ? Icons.meeting_room
                                  : Icons.event,
                          color: event.color,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      'Başlangıç',
                      '${event.startTime.day}/${event.startTime.month}/${event.startTime.year} ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                      Icons.access_time,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Bitiş',
                      '${event.endTime.day}/${event.endTime.month}/${event.endTime.year} ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                      Icons.access_time_filled,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Tür',
                      event.type == 'task'
                          ? 'Görev'
                          : event.type == 'meeting'
                              ? 'Toplantı'
                              : 'Etkinlik',
                      Icons.category,
                    ),
                  ],
                ),
              ),
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Açıklama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(event.description),
                    ],
                  ),
                ),
              ),
            ],
            if (event.attendees.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Katılımcılar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: event.attendees.length,
                        itemBuilder: (context, index) {
                          final attendee = event.attendees[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(attendee.name[0].toUpperCase()),
                            ),
                            title: Text(attendee.name),
                            subtitle: Text(attendee.email),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 