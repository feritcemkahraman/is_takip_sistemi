import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';
import '../utils/auth_helper.dart';

class MeetingMinutesSection extends StatefulWidget {
  final MeetingModel meeting;
  final VoidCallback onMinutesUpdated;

  const MeetingMinutesSection({
    Key? key,
    required this.meeting,
    required this.onMinutesUpdated,
  }) : super(key: key);

  @override
  State<MeetingMinutesSection> createState() => _MeetingMinutesSectionState();
}

class _MeetingMinutesSectionState extends State<MeetingMinutesSection> {
  final MeetingService _meetingService = MeetingService();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.meeting.minutes != null) {
      _contentController.text = widget.meeting.minutes!.content;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveMinutes() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutanak içeriği boş olamaz')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthHelper.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final minutes = MeetingMinutes(
        content: _contentController.text.trim(),
        attendees: widget.meeting.participants
            .where((p) => p.rsvpStatus == MeetingParticipant.statusAttending)
            .map((p) => p.userId)
            .toList(),
        absentees: widget.meeting.participants
            .where((p) => p.rsvpStatus == MeetingParticipant.statusDeclined)
            .map((p) => p.userId)
            .toList(),
        decisions: widget.meeting.minutes?.decisions ?? [],
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
      );

      await _meetingService.addMeetingMinutes(widget.meeting.id, minutes);
      widget.onMinutesUpdated();

      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toplantı tutanağı kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveMinutes() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthHelper.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await _meetingService.approveMeetingMinutes(
        widget.meeting.id,
        currentUser.uid,
      );
      widget.onMinutesUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toplantı tutanağı onaylandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplantı Tutanağı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!_isEditing && widget.meeting.minutes == null)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Tutanak Ekle'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Toplantı tutanağını buraya yazın...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isEditing = false),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMinutes,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ] else if (widget.meeting.minutes != null) ...[
              Text(widget.meeting.minutes!.content),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oluşturan: ${widget.meeting.minutes!.createdBy}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Tarih: ${widget.meeting.minutes!.createdAt.day}/${widget.meeting.minutes!.createdAt.month}/${widget.meeting.minutes!.createdAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (!widget.meeting.minutes!.isApproved)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _approveMinutes,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Onayla'),
                    )
                  else
                    const Chip(
                      label: Text('Onaylandı'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ] else
              const Center(
                child: Text('Henüz toplantı tutanağı eklenmemiş'),
              ),
          ],
        ),
      ),
    );
  }
} 