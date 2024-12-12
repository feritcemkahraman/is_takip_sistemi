import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../constants/app_constants.dart';
import '../screens/meeting_detail_screen.dart';

class MeetingListItem extends StatelessWidget {
  final MeetingModel meeting;

  const MeetingListItem({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        leading: Container(
          width: 12,
          height: double.infinity,
          color: AppConstants.statusColors[meeting.status],
        ),
        title: Text(meeting.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: AppConstants.statusColors[meeting.status],
                ),
                const SizedBox(width: 4),
                Text(
                  AppConstants.statusLabels[meeting.status] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_today,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '${meeting.startTime.day}/${meeting.startTime.month}/${meeting.startTime.year} '
                  '${meeting.startTime.hour}:${meeting.startTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (meeting.isOnline)
              Row(
                children: [
                  const Icon(
                    Icons.videocam,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    meeting.meetingPlatform ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        trailing: meeting.isRecurring
            ? const Icon(
                Icons.repeat,
                color: Colors.blue,
              )
            : null,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/meeting_detail',
            arguments: meeting,
          );
        },
      ),
    );
  }
} 