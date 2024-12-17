import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class EventDetailScreen extends StatefulWidget {
  final CalendarEvent event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final UserService _userService = UserService(
    firestore: FirebaseFirestore.instance,
    loggingService: LoggingService(),
  );

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
                          Icons.event,
                          color: Color(int.parse(widget.event.color)),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.event.title,
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
                      '${widget.event.startDate.day}/${widget.event.startDate.month}/${widget.event.startDate.year} ${widget.event.startDate.hour}:${widget.event.startDate.minute.toString().padLeft(2, '0')}',
                      Icons.access_time,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Bitiş',
                      '${widget.event.endDate.day}/${widget.event.endDate.month}/${widget.event.endDate.year} ${widget.event.endDate.hour}:${widget.event.endDate.minute.toString().padLeft(2, '0')}',
                      Icons.access_time_filled,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Tür',
                      'Etkinlik',
                      Icons.category,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.event.description.isNotEmpty) ...[
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
                      Text(widget.event.description),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.event.attendees.isNotEmpty) ...[
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
                      _buildAttendeesList(),
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

  Widget _buildAttendeesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.event.attendees.length,
      itemBuilder: (context, index) {
        final attendeeId = widget.event.attendees[index];
        return FutureBuilder<UserModel?>(
          future: _userService.getUser(attendeeId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Yükleniyor...'),
              );
            }

            final attendee = snapshot.data!;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(attendee.name[0].toUpperCase()),
              ),
              title: Text(attendee.name),
              subtitle: Text(attendee.email),
            );
          },
        );
      },
    );
  }
}