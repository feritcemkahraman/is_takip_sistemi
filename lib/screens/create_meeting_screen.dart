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
  String? _recurrenceType;

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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir departman seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir katılımcı seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final meetingService = Provider.of<MeetingService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) throw 'Kullanıcı bulunamadı';

      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final meeting = MeetingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _isOnline ? _meetingLinkController.text.trim() : _locationController.text.trim(),
        organizer: currentUser.uid,
        participants: _selectedParticipants,
        departments: _selectedDepartments,
        status: MeetingModel.statusScheduled,
        isOnline: _isOnline,
        meetingLink: _isOnline ? _meetingLinkController.text.trim() : null,
        meetingPlatform: _isOnline ? _selectedPlatform : null,
        createdAt: DateTime.now(),
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceType : null,
      );

      await meetingService.createMeeting(meeting);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toplantı başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Toplantı Oluştur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Toplantı Başlığı',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Toplantı Açıklaması',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Online Toplantı'),
                value: _isOnline,
                onChanged: (value) {
                  setState(() {
                    _isOnline = value;
                    _locationController.clear();
                    _meetingLinkController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isOnline) ...[
                DropdownButtonFormField<String>(
                  value: _selectedPlatform,
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
                      value: MeetingModel.platformTeams,
                      child: Text(MeetingModel.getPlatformTitle(MeetingModel.platformTeams)),
                    ),
                    DropdownMenuItem(
                      value: MeetingModel.platformMeet,
                      child: Text(MeetingModel.getPlatformTitle(MeetingModel.platformMeet)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPlatform = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _meetingLinkController,
                  labelText: 'Toplantı Linki',
                  validator: _isOnline
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen toplantı linkini girin';
                          }
                          if (!Uri.tryParse(value)!.isAbsolute) {
                            return 'Lütfen geçerli bir link girin';
                          }
                          return null;
                        }
                      : null,
                ),
              ] else ...[
                CustomTextField(
                  controller: _locationController,
                  labelText: 'Toplantı Lokasyonu',
                  validator: !_isOnline
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen toplantı lokasyonunu girin';
                          }
                          return null;
                        }
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Toplantı Zamanı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Başlangıç Tarihi'),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectStartDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Başlangıç Saati'),
                      subtitle: Text(
                        '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectStartTime,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Bitiş Tarihi'),
                      subtitle: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectEndDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Bitiş Saati'),
                      subtitle: Text(
                        '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Departmanlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.departments.map((department) {
                  return FilterChip(
                    label: Text(department),
                    selected: _selectedDepartments.contains(department),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDepartments.add(department);
                        } else {
                          _selectedDepartments.remove(department);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Tekrarlı Toplantı'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurrenceType = null;
                    }
                  });
                },
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _recurrenceType,
                  decoration: const InputDecoration(
                    labelText: 'Tekrar Sıklığı',
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
                  onChanged: (String? newValue) {
                    setState(() {
                      _recurrenceType = newValue;
                    });
                  },
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Toplantı Oluştur',
                onPressed: _isLoading ? null : _createMeeting,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 