import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';
import '../services/auth_service.dart';
import '../constants/app_theme.dart';
import '../widgets/file_upload_widget.dart';

class EditMeetingScreen extends StatefulWidget {
  final MeetingModel meeting;

  const EditMeetingScreen({super.key, required this.meeting});

  @override
  State<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _meetingLinkController;
  late DateTime _startTime;
  late DateTime _endTime;
  late bool _isOnline;
  late String _meetingPlatform;
  late List<String> _agenda;
  late List<MeetingParticipant> _participants;
  late List<String> _departments;
  final _agendaController = TextEditingController();
  late bool _isRecurring;
  late String _recurrencePattern;
  late int _recurrenceInterval;
  late List<int> _recurrenceWeekDays;
  late String _recurrenceEndType;
  late int _recurrenceOccurrences;
  late DateTime _recurrenceEndDate;
  late bool _reminderEnabled;
  late List<int> _reminderMinutes;
  late String _reminderType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _descriptionController = TextEditingController(text: widget.meeting.description);
    _locationController = TextEditingController(text: widget.meeting.location);
    _meetingLinkController = TextEditingController(text: widget.meeting.meetingLink);
    _startTime = widget.meeting.startTime;
    _endTime = widget.meeting.endTime;
    _isOnline = widget.meeting.isOnline;
    _meetingPlatform = widget.meeting.meetingPlatform ?? MeetingModel.platformZoom;
    _agenda = List.from(widget.meeting.agenda);
    _participants = List.from(widget.meeting.participants);
    _departments = List.from(widget.meeting.departments);
    _isRecurring = widget.meeting.isRecurring;
    _recurrencePattern = widget.meeting.recurrencePattern ?? MeetingModel.recurrenceDaily;
    _recurrenceInterval = widget.meeting.recurrenceInterval ?? 1;
    _recurrenceWeekDays = List.from(widget.meeting.recurrenceWeekDays ?? []);
    _recurrenceEndType = widget.meeting.recurrenceEndType ?? MeetingModel.endNever;
    _recurrenceOccurrences = widget.meeting.recurrenceOccurrences ?? 1;
    _recurrenceEndDate = widget.meeting.recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30));
    _reminderEnabled = widget.meeting.reminderEnabled;
    _reminderMinutes = List.from(widget.meeting.reminderMinutes);
    _reminderType = widget.meeting.reminderType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final currentTime = isStartTime ? _startTime : _endTime;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: currentTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentTime),
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          if (isStartTime) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            if (newDateTime.isAfter(_startTime)) {
              _endTime = newDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bitiş zamanı başlangıç zamanından önce olamaz'),
                ),
              );
            }
          }
        });
      }
    }
  }

  void _addAgendaItem() {
    final item = _agendaController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        _agenda.add(item);
        _agendaController.clear();
      });
    }
  }

  void _removeAgendaItem(int index) {
    setState(() {
      _agenda.removeAt(index);
    });
  }

  void _removeParticipant(String userId) {
    setState(() {
      _participants.removeWhere((p) => p.userId == userId);
    });
  }

  Future<void> _saveMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final meetingService = Provider.of<MeetingService>(context, listen: false);
      final updatedMeeting = widget.meeting.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: _startTime,
        endTime: _endTime,
        isOnline: _isOnline,
        meetingPlatform: _isOnline ? _meetingPlatform : null,
        meetingLink: _isOnline ? _meetingLinkController.text : null,
        location: _isOnline ? '' : _locationController.text,
        agenda: _agenda,
        participants: _participants,
        departments: _departments,
        isRecurring: _isRecurring,
        recurrencePattern: _isRecurring ? _recurrencePattern : null,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
        recurrenceWeekDays: _isRecurring ? _recurrenceWeekDays : null,
        recurrenceEndType: _isRecurring ? _recurrenceEndType : null,
        recurrenceOccurrences: _isRecurring ? _recurrenceOccurrences : null,
        recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        reminderEnabled: _reminderEnabled,
        reminderMinutes: _reminderMinutes,
        reminderType: _reminderType,
        lastUpdatedAt: DateTime.now(),
      );

      if (widget.meeting.parentMeetingId != null) {
        // Tekrarlayan toplantı serisini güncelle
        await meetingService.updateRecurringMeetings(
          widget.meeting.parentMeetingId!,
          updatedMeeting,
        );
      } else {
        // Tek toplantıyı güncelle
        await meetingService.updateMeeting(updatedMeeting);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantıyı Düzenle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveMeeting,
            child: const Text(
              'Kaydet',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Toplantı Başlığı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Başlık gereklidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildDateTimeSection(),
            const SizedBox(height: 16),
            _buildLocationSection(),
            const SizedBox(height: 16),
            _buildRecurrenceSection(),
            const SizedBox(height: 16),
            _buildReminderSection(),
            const SizedBox(height: 16),
            _buildAgendaSection(),
            const SizedBox(height: 16),
            _buildParticipantsSection(),
            const SizedBox(height: 16),
            _buildDepartmentsSection(),
            const SizedBox(height: 16),
            _buildAttachmentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarih ve Saat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Başlangıç'),
                subtitle: Text(
                  '${_startTime.day}/${_startTime.month}/${_startTime.year} ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Bitiş'),
                subtitle: Text(
                  '${_endTime.day}/${_endTime.month}/${_endTime.year} ${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konum',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Online Toplantı'),
          value: _isOnline,
          onChanged: (value) {
            setState(() {
              _isOnline = value;
            });
          },
        ),
        if (_isOnline) ...[
          DropdownButtonFormField<String>(
            value: _meetingPlatform,
            decoration: const InputDecoration(
              labelText: 'Platform',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: MeetingModel.platformZoom,
                child: Text(MeetingModel.getPlatformTitle(MeetingModel.platformZoom)),
              ),
              DropdownMenuItem(
                value: MeetingModel.platformMeet,
                child: Text(MeetingModel.getPlatformTitle(MeetingModel.platformMeet)),
              ),
              DropdownMenuItem(
                value: MeetingModel.platformTeams,
                child: Text(MeetingModel.getPlatformTitle(MeetingModel.platformTeams)),
              ),
              DropdownMenuItem(
                value: MeetingModel.platformSkype,
                child: Text(MeetingModel.getPlatformTitle(MeetingModel.platformSkype)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _meetingPlatform = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _meetingLinkController,
            decoration: const InputDecoration(
              labelText: 'Toplantı Linki',
              border: OutlineInputBorder(),
            ),
          ),
        ] else
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Konum',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecurrenceSection() {
    if (widget.meeting.parentMeetingId != null) {
      return const SizedBox(); // Tekrarlayan toplantı serisinin bir parçası ise gösterme
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tekrarlama',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Toplantıyı Tekrarla'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
          },
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _recurrencePattern,
            decoration: const InputDecoration(
              labelText: 'Tekrarlama Deseni',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: MeetingModel.recurrenceDaily,
                child: Text(MeetingModel.getRecurrenceTitle(MeetingModel.recurrenceDaily)),
              ),
              DropdownMenuItem(
                value: MeetingModel.recurrenceWeekly,
                child: Text(MeetingModel.getRecurrenceTitle(MeetingModel.recurrenceWeekly)),
              ),
              DropdownMenuItem(
                value: MeetingModel.recurrenceMonthly,
                child: Text(MeetingModel.getRecurrenceTitle(MeetingModel.recurrenceMonthly)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _recurrencePattern = value;
                  if (value != MeetingModel.recurrenceWeekly) {
                    _recurrenceWeekDays.clear();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _recurrenceInterval.toString(),
                  decoration: InputDecoration(
                    labelText: 'Her',
                    suffixText: _recurrencePattern == MeetingModel.recurrenceDaily
                        ? 'gün'
                        : _recurrencePattern == MeetingModel.recurrenceWeekly
                            ? 'hafta'
                            : 'ay',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final interval = int.tryParse(value);
                    if (interval != null && interval > 0) {
                      setState(() {
                        _recurrenceInterval = interval;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          if (_recurrencePattern == MeetingModel.recurrenceWeekly) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final weekDay = index + 1;
                return FilterChip(
                  label: Text(MeetingModel.weekDays[index]),
                  selected: _recurrenceWeekDays.contains(weekDay),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _recurrenceWeekDays.add(weekDay);
                      } else {
                        _recurrenceWeekDays.remove(weekDay);
                      }
                    });
                  },
                );
              }),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _recurrenceEndType,
            decoration: const InputDecoration(
              labelText: 'Tekrarlama Sonu',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: MeetingModel.endNever,
                child: Text(MeetingModel.getEndTypeTitle(MeetingModel.endNever)),
              ),
              DropdownMenuItem(
                value: MeetingModel.endAfterOccurrences,
                child: Text(MeetingModel.getEndTypeTitle(MeetingModel.endAfterOccurrences)),
              ),
              DropdownMenuItem(
                value: MeetingModel.endOnDate,
                child: Text(MeetingModel.getEndTypeTitle(MeetingModel.endOnDate)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _recurrenceEndType = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          if (_recurrenceEndType == MeetingModel.endAfterOccurrences)
            TextFormField(
              initialValue: _recurrenceOccurrences.toString(),
              decoration: const InputDecoration(
                labelText: 'Tekrar Sayısı',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final occurrences = int.tryParse(value);
                if (occurrences != null && occurrences > 0) {
                  setState(() {
                    _recurrenceOccurrences = occurrences;
                  });
                }
              },
            )
          else if (_recurrenceEndType == MeetingModel.endOnDate)
            ListTile(
              title: const Text('Bitiş Tarihi'),
              subtitle: Text(
                '${_recurrenceEndDate.day}/${_recurrenceEndDate.month}/${_recurrenceEndDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _recurrenceEndDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (date != null) {
                  setState(() {
                    _recurrenceEndDate = date;
                  });
                }
              },
            ),
        ],
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hatırlatmalar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Hatırlatmaları Etkinleştir'),
          value: _reminderEnabled,
          onChanged: (value) {
            setState(() {
              _reminderEnabled = value;
            });
          },
        ),
        if (_reminderEnabled) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _reminderType,
            decoration: const InputDecoration(
              labelText: 'Hatırlatma Türü',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: MeetingModel.reminderTypeApp,
                child: Text(MeetingModel.getReminderTypeTitle(MeetingModel.reminderTypeApp)),
              ),
              DropdownMenuItem(
                value: MeetingModel.reminderTypeEmail,
                child: Text(MeetingModel.getReminderTypeTitle(MeetingModel.reminderTypeEmail)),
              ),
              DropdownMenuItem(
                value: MeetingModel.reminderTypeBoth,
                child: Text(MeetingModel.getReminderTypeTitle(MeetingModel.reminderTypeBoth)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _reminderType = value;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Hatırlatma Zamanları',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MeetingModel.reminderTimes.map((minutes) {
              final isSelected = _reminderMinutes.contains(minutes);
              return FilterChip(
                label: Text(MeetingModel.formatReminderTime(minutes)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _reminderMinutes.add(minutes);
                      _reminderMinutes.sort();
                    } else {
                      _reminderMinutes.remove(minutes);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_reminderMinutes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'En az bir hatırlatma zamanı seçin',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAgendaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gündem Maddeleri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _agendaController,
                decoration: const InputDecoration(
                  hintText: 'Yeni gündem maddesi ekle',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addAgendaItem,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _agenda.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(_agenda[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeAgendaItem(index),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Katılımcılar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Ekle'),
              onPressed: () {
                // TODO: Katılımcı ekleme dialogu
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _participants.map((participant) {
            return Chip(
              avatar: const CircleAvatar(
                child: Icon(Icons.person, size: 16),
              ),
              label: Text(participant.name),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () => _removeParticipant(participant.userId),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDepartmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Departmanlar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
              onPressed: () {
                // TODO: Departman ekleme dialogu
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _departments.map((department) {
            return Chip(
              label: Text(department),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _departments.remove(department);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ekler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        FileUploadWidget(
          onFileSelected: (files) {
            // TODO: Dosya yükleme işlemi
          },
        ),
      ],
    );
  }
} 