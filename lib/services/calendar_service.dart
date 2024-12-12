import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_model.dart';
import '../models/meeting_model.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Google Calendar API için gerekli kimlik bilgileri
  static String get _clientId => AppConstants.googleClientId;
  static String get _clientSecret => AppConstants.googleClientSecret;
  static const _scopes = [google_calendar.CalendarApi.calendarScope];

  // Firestore koleksiyon referansları
  CollectionReference get _events => _firestore.collection('calendar_events');
  CollectionReference get _settings => _firestore.collection('calendar_settings');

  // Google Calendar kimlik bilgilerini kontrol et
  bool get isGoogleCalendarConfigured {
    return _clientId.isNotEmpty && _clientSecret.isNotEmpty;
  }

  // Takvim ayarlarını getir
  Stream<CalendarSettings> getSettings(String userId) {
    return _settings
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists
            ? CalendarSettings.fromMap(doc.data() as Map<String, dynamic>)
            : CalendarSettings(userId: userId));
  }

  // Takvim ayarlarını güncelle
  Future<void> updateSettings(CalendarSettings settings) async {
    await _settings.doc(settings.userId).set(settings.toMap());
  }

  // Belirli bir tarih aralığındaki etkinlikleri getir
  Stream<List<CalendarEvent>> getEvents(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _events
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Toplantıyı takvime ekle
  Future<void> addMeetingToCalendar(MeetingModel meeting) async {
    final event = CalendarEvent(
      id: const Uuid().v4(),
      title: meeting.title,
      description: meeting.description,
      startTime: meeting.startTime,
      endTime: meeting.endTime,
      type: CalendarEvent.typeMeeting,
      sourceId: meeting.id,
      userId: meeting.organizerId,
      color: CalendarEvent.colorMeeting,
    );

    await _events.doc(event.id).set(event.toMap());

    // Google Calendar senkronizasyonu
    final settings = await _settings.doc(meeting.organizerId).get();
    if (settings.exists) {
      final calendarSettings = CalendarSettings.fromMap(
        settings.data() as Map<String, dynamic>,
      );
      if (calendarSettings.isGoogleCalendarEnabled) {
        await _syncEventWithGoogleCalendar(event);
      }
    }
  }

  // Görevi takvime ekle
  Future<void> addTaskToCalendar(TaskModel task) async {
    final event = CalendarEvent(
      id: const Uuid().v4(),
      title: task.title,
      description: task.description,
      startTime: task.startDate,
      endTime: task.dueDate,
      type: CalendarEvent.typeTask,
      sourceId: task.id,
      userId: task.assignedTo,
      color: task.priority == TaskModel.priorityHigh
          ? CalendarEvent.colorDeadline
          : CalendarEvent.colorTask,
    );

    await _events.doc(event.id).set(event.toMap());

    // Google Calendar senkronizasyonu
    final settings = await _settings.doc(task.assignedTo).get();
    if (settings.exists) {
      final calendarSettings = CalendarSettings.fromMap(
        settings.data() as Map<String, dynamic>,
      );
      if (calendarSettings.isGoogleCalendarEnabled) {
        await _syncEventWithGoogleCalendar(event);
      }
    }
  }

  // Takvim etkinliğini güncelle
  Future<void> updateEvent(CalendarEvent event) async {
    await _events.doc(event.id).update(event.toMap());

    if (event.isSynced && event.externalEventId != null) {
      await _updateGoogleCalendarEvent(event);
    }
  }

  // Takvim etkinliğini sil
  Future<void> deleteEvent(String eventId) async {
    final event = await _events.doc(eventId).get();
    if (event.exists) {
      final calendarEvent = CalendarEvent.fromMap(
        event.data() as Map<String, dynamic>,
      );
      
      if (calendarEvent.isSynced && calendarEvent.externalEventId != null) {
        await _deleteGoogleCalendarEvent(calendarEvent);
      }

      await _events.doc(eventId).delete();
    }
  }

  // Google Calendar ile senkronizasyon
  Future<void> _syncEventWithGoogleCalendar(CalendarEvent event) async {
    try {
      final client = await _getGoogleAuthClient();
      final calendar = google_calendar.CalendarApi(client);

      final googleEvent = google_calendar.Event()
        ..summary = event.title
        ..description = event.description
        ..start = google_calendar.EventDateTime()
          ..dateTime = event.startTime.toUtc()
          ..timeZone = 'UTC'
        ..end = google_calendar.EventDateTime()
          ..dateTime = event.endTime.toUtc()
          ..timeZone = 'UTC';

      final createdEvent = await calendar.events.insert(
        googleEvent,
        'primary',
      );

      // Firestore'daki etkinliği güncelle
      await _events.doc(event.id).update({
        'isSynced': true,
        'externalEventId': createdEvent.id,
      });
    } catch (e) {
      print('Google Calendar senkronizasyon hatası: $e');
    }
  }

  Future<void> _updateGoogleCalendarEvent(CalendarEvent event) async {
    try {
      final client = await _getGoogleAuthClient();
      final calendar = google_calendar.CalendarApi(client);

      final googleEvent = google_calendar.Event()
        ..summary = event.title
        ..description = event.description
        ..start = google_calendar.EventDateTime()
          ..dateTime = event.startTime.toUtc()
          ..timeZone = 'UTC'
        ..end = google_calendar.EventDateTime()
          ..dateTime = event.endTime.toUtc()
          ..timeZone = 'UTC';

      await calendar.events.update(
        googleEvent,
        'primary',
        event.externalEventId!,
      );
    } catch (e) {
      print('Google Calendar güncelleme hatası: $e');
    }
  }

  Future<void> _deleteGoogleCalendarEvent(CalendarEvent event) async {
    try {
      final client = await _getGoogleAuthClient();
      final calendar = google_calendar.CalendarApi(client);

      await calendar.events.delete(
        'primary',
        event.externalEventId!,
      );
    } catch (e) {
      print('Google Calendar silme hatası: $e');
    }
  }

  Future<AuthClient> _getGoogleAuthClient() async {
    final credentials = ClientId(
      _clientId,
      _clientSecret,
    );

    return await clientViaUserConsent(
      credentials,
      _scopes,
      (url) async {
        await launchUrl(Uri.parse(url));
      },
    );
  }

  // Tüm takvim etkinliklerini senkronize et
  Future<void> syncAllEvents(String userId) async {
    final settings = await _settings.doc(userId).get();
    if (!settings.exists) return;

    final calendarSettings = CalendarSettings.fromMap(
      settings.data() as Map<String, dynamic>,
    );

    if (!calendarSettings.isGoogleCalendarEnabled) return;

    final events = await _events
        .where('userId', isEqualTo: userId)
        .where('isSynced', isEqualTo: false)
        .get();

    for (var doc in events.docs) {
      final event = CalendarEvent.fromMap(doc.data() as Map<String, dynamic>);
      await _syncEventWithGoogleCalendar(event);
    }

    // Son senkronizasyon zamanını güncelle
    await _settings.doc(userId).update({
      'lastSyncTime': FieldValue.serverTimestamp(),
    });
  }
} 