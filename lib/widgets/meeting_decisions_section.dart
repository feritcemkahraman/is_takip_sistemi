import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';
import '../utils/auth_helper.dart';

class MeetingDecisionsSection extends StatefulWidget {
  final MeetingModel meeting;
  final VoidCallback onDecisionsUpdated;

  const MeetingDecisionsSection({
    Key? key,
    required this.meeting,
    required this.onDecisionsUpdated,
  }) : super(key: key);

  @override
  State<MeetingDecisionsSection> createState() => _MeetingDecisionsSectionState();
}

class _MeetingDecisionsSectionState extends State<MeetingDecisionsSection> {
  final MeetingService _meetingService = MeetingService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  String? _selectedAssignee;
  bool _isAdding = false;
  bool _isLoading = false;
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _contentController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
        _dueDateController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  Future<void> _addDecision() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karar içeriği boş olamaz')),
      );
      return;
    }

    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir termin tarihi seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthHelper.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final decision = MeetingDecision(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _contentController.text.trim(),
        assignedTo: _selectedAssignee,
        dueDate: _selectedDueDate!,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
      );

      await _meetingService.addMeetingDecision(widget.meeting.id, decision);
      widget.onDecisionsUpdated();

      setState(() {
        _isAdding = false;
        _contentController.clear();
        _dueDateController.clear();
        _selectedAssignee = null;
        _selectedDueDate = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karar başarıyla eklendi')),
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

  Future<void> _updateDecisionStatus(String decisionId, String status) async {
    setState(() => _isLoading = true);

    try {
      if (status == MeetingDecision.statusCompleted) {
        await _meetingService.completeMeetingDecision(
          widget.meeting.id,
          decisionId,
        );
      } else if (status == MeetingDecision.statusCancelled) {
        await _meetingService.cancelMeetingDecision(
          widget.meeting.id,
          decisionId,
        );
      }

      widget.onDecisionsUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karar durumu güncellendi')),
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
                  'Kararlar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!_isAdding)
                  TextButton.icon(
                    onPressed: () => setState(() => _isAdding = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Karar Ekle'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isAdding) ...[
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Karar',
                  hintText: 'Kararı buraya yazın...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAssignee,
                      decoration: const InputDecoration(
                        labelText: 'Sorumlu',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.meeting.participants.map((participant) {
                        return DropdownMenuItem(
                          value: participant.userId,
                          child: Text(participant.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAssignee = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _dueDateController,
                      readOnly: true,
                      onTap: _selectDueDate,
                      decoration: const InputDecoration(
                        labelText: 'Termin Tarihi',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isAdding = false),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addDecision,
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
            ],
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.meeting.decisions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final decision = widget.meeting.decisions[index];
                final assignee = widget.meeting.participants
                    .firstWhere((p) => p.userId == decision.assignedTo);

                return ListTile(
                  title: Text(decision.content),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text('Sorumlu: ${assignee.name}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Termin: ${decision.dueDate.day}/${decision.dueDate.month}/${decision.dueDate.year}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: decision.status == MeetingDecision.statusPending
                      ? PopupMenuButton<String>(
                          onSelected: (status) =>
                              _updateDecisionStatus(decision.id, status),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: MeetingDecision.statusCompleted,
                              child: Text('Tamamlandı'),
                            ),
                            const PopupMenuItem(
                              value: MeetingDecision.statusCancelled,
                              child: Text('İptal Et'),
                            ),
                          ],
                          child: Chip(
                            label: Text(MeetingDecision.getStatusTitle(
                              decision.status,
                            )),
                            backgroundColor: MeetingDecision.getStatusColor(
                              decision.status,
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        )
                      : Chip(
                          label: Text(MeetingDecision.getStatusTitle(
                            decision.status,
                          )),
                          backgroundColor: MeetingDecision.getStatusColor(
                            decision.status,
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 