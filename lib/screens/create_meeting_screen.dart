import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/meeting_service.dart';
import '../services/auth_service.dart';
import '../models/meeting_model.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();

  bool _isLoading = false;
  bool _isOnline = false;
  String _selectedPlatform = MeetingModel.platformZoom;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();
  List<String> _selectedDepartments = [];
  List<String> _selectedParticipants = [];
  bool _isRecurring = false;
  String _recurrencePattern = MeetingModel.recurrenceDaily;
  int _recurrenceInterval = 1;
  List<int> _recurrenceWeekDays = [];
  String _recurrenceEndType = MeetingModel.endNever;
  int? _recurrenceOccurrences;
  DateTime? _recurrenceEndDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      if (_endDate.isBefore(_startDate)) {
        setState(() => _endDate = _startDate);
      }
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _createMeeting() async {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring &&
          _recurrencePattern == MeetingModel.recurrenceWeekly &&
          _recurrenceWeekDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen en az bir gün seçin'),
          ),
        );
        return;
      }

      try {
        setState(() {
          _isLoading = true;
        });

        final meeting = MeetingModel(
          id: const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: _startDate!,
          endTime: _endDate!,
          organizerId: _currentUser!.uid,
          participants: _selectedParticipants,
          departments: _selectedDepartments,
          agenda: _agendaItems,
          isOnline: _isOnlineMeeting,
          meetingPlatform: _selectedPlatform,
          meetingLink: _meetingLinkController.text,
          location: _locationController.text,
          status: MeetingModel.statusScheduled,
          createdAt: DateTime.now(),
          isRecurring: _isRecurring,
          recurrencePattern: _recurrencePattern,
          recurrenceInterval: _recurrenceInterval,
          recurrenceWeekDays: _recurrenceWeekDays,
          recurrenceEndType: _recurrenceEndType,
          recurrenceOccurrences: _recurrenceOccurrences,
          recurrenceEndDate: _recurrenceEndDate,
        );

        if (_isRecurring) {
          await _meetingService.createRecurringMeetings(meeting);
        } else {
          await _meetingService.createMeeting(meeting);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toplantı başarıyla oluşturuldu')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildRecurrenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value ?? false;
                    });
                  },
                ),
                const Text('Toplantıyı Tekrarla'),
              ],
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurrencePattern,
                decoration: const InputDecoration(
                  labelText: 'Tekrarlama Deseni',
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
                  setState(() {
                    _recurrencePattern = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _recurrenceInterval.toString(),
                decoration: const InputDecoration(
                  labelText: 'Tekrarlama Aralığı',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir değer girin';
                  }
                  final interval = int.tryParse(value);
                  if (interval == null || interval < 1) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
                onChanged: (value) {
                  final interval = int.tryParse(value);
                  if (interval != null && interval > 0) {
                    setState(() {
                      _recurrenceInterval = interval;
                    });
                  }
                },
              ),
              if (_recurrencePattern == MeetingModel.recurrenceWeekly) ...[
                const SizedBox(height: 16),
                const Text('Tekrarlama Günleri'),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final weekDay = index + 1;
                    return FilterChip(
                      label: Text(weekDays[index]),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurrenceEndType,
                decoration: const InputDecoration(
                  labelText: 'Tekrarlama Sonu',
                ),
                items: [
                  DropdownMenuItem(
                    value: MeetingModel.endNever,
                    child: const Text('Süresiz'),
                  ),
                  DropdownMenuItem(
                    value: MeetingModel.endAfterOccurrences,
                    child: const Text('Belirli sayıda tekrar sonra'),
                  ),
                  DropdownMenuItem(
                    value: MeetingModel.endOnDate,
                    child: const Text('Belirli bir tarihte'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurrenceEndType = value!;
                  });
                },
              ),
              if (_recurrenceEndType == MeetingModel.endAfterOccurrences) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _recurrenceOccurrences?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Tekrar Sayısı',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir değer girin';
                    }
                    final occurrences = int.tryParse(value);
                    if (occurrences == null || occurrences < 1) {
                      return 'Geçerli bir sayı girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final occurrences = int.tryParse(value);
                    if (occurrences != null && occurrences > 0) {
                      setState(() {
                        _recurrenceOccurrences = occurrences;
                      });
                    }
                  },
                ),
              ],
              if (_recurrenceEndType == MeetingModel.endOnDate) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _recurrenceEndDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setState(() {
                        _recurrenceEndDate = date;
                      });
                    }
                  },
                  child: Text(_recurrenceEndDate != null
                      ? 'Bitiş Tarihi: ${DateFormat('dd/MM/yyyy').format(_recurrenceEndDate!)}'
                      : 'Bitiş Tarihi Seç'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Toplantı Oluştur'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 16),
                    _buildDateTimeSection(),
                    const SizedBox(height: 16),
                    _buildParticipantsSection(),
                    const SizedBox(height: 16),
                    _buildDepartmentsSection(),
                    const SizedBox(height: 16),
                    _buildAgendaSection(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildRecurrenceSection(),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _createMeeting,
                        child: const Text('Toplantı Oluştur'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 