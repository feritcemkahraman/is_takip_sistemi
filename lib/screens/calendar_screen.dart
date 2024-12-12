import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_model.dart';
import '../services/calendar_service.dart';
import '../services/auth_service.dart';
import '../constants/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late CalendarSettings _settings;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _rangeStart = DateTime.now().subtract(const Duration(days: 7));
    _rangeEnd = DateTime.now().add(const Duration(days: 7));
    _calendarFormat = CalendarFormat.month;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final calendarService = Provider.of<CalendarService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takvim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => calendarService.syncAllEvents(currentUser.uid),
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<CalendarSettings>(
            stream: calendarService.getSettings(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _settings = snapshot.data!;
                return _buildCalendar(context);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          Expanded(
            child: StreamBuilder<List<CalendarEvent>>(
              stream: calendarService.getEvents(
                currentUser.uid,
                _rangeStart,
                _rangeEnd,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildEventList(snapshot.data!);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      startingDayOfWeek: _settings.firstDayOfWeek == 'monday'
          ? StartingDayOfWeek.monday
          : StartingDayOfWeek.sunday,
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: Colors.red),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          _rangeStart = focusedDay.subtract(const Duration(days: 7));
          _rangeEnd = focusedDay.add(const Duration(days: 7));
        });
      },
    );
  }

  Widget _buildEventList(List<CalendarEvent> events) {
    // Seçili güne ait etkinlikleri filtrele
    final dayEvents = events.where((event) {
      return isSameDay(event.startTime, _selectedDay) ||
          (event.startTime.isBefore(_selectedDay) &&
              event.endTime.isAfter(_selectedDay));
    }).toList();

    if (dayEvents.isEmpty) {
      return const Center(
        child: Text('Bu tarihte etkinlik bulunmuyor'),
      );
    }

    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            leading: Container(
              width: 12,
              height: double.infinity,
              color: Color(
                int.parse(event.color.replaceAll('#', '0xFF')),
              ),
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.description),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: event.isSynced
                ? const Icon(
                    Icons.sync,
                    color: Colors.green,
                  )
                : null,
            onTap: () => _showEventDetails(context, event),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final calendarService = Provider.of<CalendarService>(context, listen: false);
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;

    if (currentUser == null) return;

    bool isGoogleEnabled = _settings.isGoogleCalendarEnabled;
    bool showWeekends = _settings.showWeekends;
    String firstDayOfWeek = _settings.firstDayOfWeek;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Takvim Ayarları'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (calendarService.isGoogleCalendarConfigured)
                SwitchListTile(
                  title: const Text('Google Calendar'),
                  value: isGoogleEnabled,
                  onChanged: (value) {
                    setState(() {
                      isGoogleEnabled = value;
                    });
                  },
                )
              else
                ListTile(
                  title: const Text('Google Calendar'),
                  subtitle: const Text(
                    'Google Calendar entegrasyonu için yöneticinize başvurun',
                  ),
                  leading: const Icon(Icons.warning, color: Colors.orange),
                ),
              SwitchListTile(
                title: const Text('Hafta Sonlarını Göster'),
                value: showWeekends,
                onChanged: (value) {
                  setState(() {
                    showWeekends = value;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: firstDayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Haftanın İlk Günü',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'monday',
                    child: Text('Pazartesi'),
                  ),
                  DropdownMenuItem(
                    value: 'sunday',
                    child: Text('Pazar'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    firstDayOfWeek = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final newSettings = _settings.copyWith(
                isGoogleCalendarEnabled: isGoogleEnabled,
                showWeekends: showWeekends,
                firstDayOfWeek: firstDayOfWeek,
              );

              await calendarService.updateSettings(newSettings);
              if (mounted) Navigator.pop(context);

              if (isGoogleEnabled &&
                  !_settings.isGoogleCalendarEnabled &&
                  calendarService.isGoogleCalendarConfigured) {
                // Google Calendar senkronizasyonunu başlat
                await calendarService.syncAllEvents(currentUser.uid);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventDetails(BuildContext context, CalendarEvent event) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 16),
            Text(
              'Başlangıç: ${_formatDateTime(event.startTime)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Bitiş: ${_formatDateTime(event.endTime)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tür: ${event.type == CalendarEvent.typeMeeting ? 'Toplantı' : 'Görev'}',
            ),
            if (event.isSynced)
              const Text(
                'Google Calendar ile senkronize edildi',
                style: TextStyle(
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }
} 