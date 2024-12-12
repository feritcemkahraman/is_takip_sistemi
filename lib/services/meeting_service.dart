import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Toplantı koleksiyonu referansı
  CollectionReference get _meetingsRef => _firestore.collection('meetings');

  // Toplantı oluşturma
  Future<void> createMeeting(MeetingModel meeting) async {
    final docRef = _meetingsRef.doc(meeting.id);
    await docRef.set(meeting.toMap());

    // Tekrarlayan toplantı ise seriyi oluştur
    if (meeting.isRecurring) {
      await createRecurringMeetings(meeting);
    }

    // Katılımcılara bildirim gönder
    for (final participant in meeting.participants) {
      await _notificationService.createNotification(
        title: 'Yeni Toplantı Daveti',
        message: '${meeting.title} toplantısına davet edildiniz.',
        type: NotificationModel.typeMeetingInvite,
        userId: participant.userId,
        taskId: meeting.id,
        senderId: meeting.organizerId,
      );
    }
  }

  // Toplantı güncelleme
  Future<void> updateMeeting(MeetingModel meeting) async {
    final docRef = _meetingsRef.doc(meeting.id);
    await docRef.update(meeting.toMap());

    // Tekrarlayan toplantı serisini güncelle
    if (meeting.parentMeetingId != null) {
      await updateRecurringMeetings(meeting.parentMeetingId!, meeting);
    }

    // Katılımcılara bildirim gönder
    for (final participant in meeting.participants) {
      await _notificationService.createNotification(
        title: 'Toplantı Güncellendi',
        message: '${meeting.title} toplantısında değişiklik yapıldı.',
        type: NotificationModel.typeMeetingUpdate,
        userId: participant.userId,
        taskId: meeting.id,
        senderId: meeting.organizerId,
      );
    }
  }

  // Toplantı silme
  Future<void> deleteMeeting(String meetingId) async {
    final docRef = _meetingsRef.doc(meetingId);
    final meeting = await docRef.get();
    
    if (meeting.exists) {
      final meetingData = meeting.data() as Map<String, dynamic>;
      final meetingModel = MeetingModel.fromMap(meetingData);

      // Tekrarlayan toplantı serisini iptal et
      if (meetingModel.parentMeetingId != null) {
        await cancelRecurringMeetings(meetingModel.parentMeetingId!);
      }

      // Katılımcılara bildirim gönder
      for (final participant in meetingModel.participants) {
        await _notificationService.createNotification(
          title: 'Toplantı İptal Edildi',
          message: '${meetingModel.title} toplantısı iptal edildi.',
          type: NotificationModel.typeMeetingCancelled,
          userId: participant.userId,
          taskId: meetingId,
          senderId: meetingModel.organizerId,
        );
      }
    }

    await docRef.delete();
  }

  // Toplantı durumunu güncelleme
  Future<void> updateMeetingStatus(String meetingId, String status) async {
    final docRef = _meetingsRef.doc(meetingId);
    await docRef.update({'status': status});

    final meeting = await docRef.get();
    if (meeting.exists) {
      final meetingData = meeting.data() as Map<String, dynamic>;
      final meetingModel = MeetingModel.fromMap(meetingData);

      String message;
      String type;

      switch (status) {
        case MeetingModel.statusOngoing:
          message = '${meetingModel.title} toplantısı başladı.';
          type = NotificationModel.typeMeetingStatus;
          break;
        case MeetingModel.statusCompleted:
          message = '${meetingModel.title} toplantısı tamamlandı.';
          type = NotificationModel.typeMeetingStatus;
          break;
        case MeetingModel.statusCancelled:
          message = '${meetingModel.title} toplantısı iptal edildi.';
          type = NotificationModel.typeMeetingCancelled;
          break;
        default:
          return;
      }

      // Katılımcılara bildirim gönder
      for (final participant in meetingModel.participants) {
        await _notificationService.createNotification(
          title: 'Toplantı Durumu Değişti',
          message: message,
          type: type,
          userId: participant.userId,
          taskId: meetingId,
          senderId: meetingModel.organizerId,
        );
      }
    }
  }

  // Toplantı notları
  Future<void> addMeetingNote(
    String meetingId,
    String content,
    String createdBy,
  ) async {
    final note = MeetingNote(
      content: content,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final docRef = _meetingsRef.doc(meetingId);
    await docRef.update({
      'notes': FieldValue.arrayUnion([note.toMap()]),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    final meeting = await docRef.get();
    if (meeting.exists) {
      final meetingData = meeting.data() as Map<String, dynamic>;
      final meetingModel = MeetingModel.fromMap(meetingData);

      // Katılımcılara bildirim gönder
      for (final participant in meetingModel.participants) {
        await _notificationService.createNotification(
          title: 'Yeni Toplantı Notu',
          message: '${meetingModel.title} toplantısına yeni not eklendi.',
          type: NotificationModel.typeMeetingNote,
          userId: participant.userId,
          taskId: meetingId,
          senderId: meetingModel.organizerId,
        );
      }
    }
  }

  // RSVP işlemleri
  Future<void> updateRsvpStatus(
    String meetingId,
    String userId,
    String userName,
    String status,
  ) async {
    final docRef = _meetingsRef.doc(meetingId);
    final meeting = await docRef.get();

    if (!meeting.exists) {
      throw Exception('Toplantı bulunamadı');
    }

    final meetingData = meeting.data() as Map<String, dynamic>;
    final meetingModel = MeetingModel.fromMap(meetingData);

    // Katılımcı listesini güncelle
    final participants = List<MeetingParticipant>.from(meetingModel.participants);
    final participantIndex = participants.indexWhere((p) => p.userId == userId);

    if (participantIndex != -1) {
      // Mevcut katılımcıyı güncelle
      participants[participantIndex] = MeetingParticipant(
        userId: userId,
        name: userName,
        rsvpStatus: status,
        respondedAt: DateTime.now(),
      );
    } else {
      // Yeni katılımcı ekle
      participants.add(MeetingParticipant(
        userId: userId,
        name: userName,
        rsvpStatus: status,
        respondedAt: DateTime.now(),
      ));
    }

    // Toplantıyı güncelle
    await docRef.update({
      'participants': participants.map((p) => p.toMap()).toList(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Organizatöre bildirim gönder
    String message;
    switch (status) {
      case MeetingParticipant.statusAttending:
        message = '$userName toplantıya katılacağını bildirdi.';
        break;
      case MeetingParticipant.statusDeclined:
        message = '$userName toplantıya katılamayacağını bildirdi.';
        break;
      default:
        return;
    }

    await _notificationService.createNotification(
      title: 'RSVP Yanıtı',
      message: message,
      type: NotificationModel.typeMeetingStatus,
      userId: meetingModel.organizerId,
      taskId: meetingId,
      senderId: userId,
    );
  }

  // Kullanıcının toplantılarını getir
  Stream<List<MeetingModel>> getUserMeetings(String userId) {
    return _meetingsRef
        .where('participants', arrayContains: {'userId': userId})
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Yaklaşan toplantıları getir
  Stream<List<MeetingModel>> getUpcomingMeetings(String userId) {
    final now = DateTime.now();
    return _meetingsRef
        .where('participants', arrayContains: {'userId': userId})
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .where('status', isEqualTo: MeetingModel.statusScheduled)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Departman toplantılarını getir
  Stream<List<MeetingModel>> getDepartmentMeetings(String department) {
    return _meetingsRef
        .where('departments', arrayContains: department)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Toplantı detaylarını getir
  Future<MeetingModel?> getMeeting(String meetingId) async {
    final doc = await _meetingsRef.doc(meetingId).get();
    if (!doc.exists) return null;
    return MeetingModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Tekrarlayan toplantı serisi oluştur
  Future<List<String>> createRecurringMeetings(MeetingModel meeting) async {
    if (!meeting.isRecurring) {
      throw Exception('Toplantı tekrarlayan olarak işaretlenmemiş');
    }

    final createdMeetingIds = <String>[];
    DateTime currentDate = meeting.startTime;
    int occurrenceCount = 0;

    while (true) {
      // Tekrarlama sonu kontrolü
      if (meeting.recurrenceEndType == MeetingModel.endAfterOccurrences &&
          occurrenceCount >= (meeting.recurrenceOccurrences ?? 0)) {
        break;
      }

      if (meeting.recurrenceEndType == MeetingModel.endOnDate &&
          meeting.recurrenceEndDate != null &&
          currentDate.isAfter(meeting.recurrenceEndDate!)) {
        break;
      }

      // Yeni toplantı ID'si oluştur
      final meetingId = _meetingsRef.doc().id;
      createdMeetingIds.add(meetingId);

      // Toplantı süresini hesapla
      final duration = meeting.endTime.difference(meeting.startTime);
      final endDate = currentDate.add(duration);

      // Yeni toplantı oluştur
      final newMeeting = meeting.copyWith(
        id: meetingId,
        startTime: currentDate,
        endTime: endDate,
        parentMeetingId: meeting.id,
        createdAt: DateTime.now(),
      );

      // Toplantıyı kaydet
      await _meetingsRef.doc(meetingId).set(newMeeting.toMap());

      // Katılımcılara bildirim gönder
      for (final participant in meeting.participants) {
        await _notificationService.createNotification(
          title: 'Yeni Toplantı Serisi',
          message: '${meeting.title} toplantı serisine davet edildiniz.',
          type: NotificationModel.typeMeetingInvite,
          userId: participant.userId,
          taskId: meetingId,
          senderId: meeting.organizerId,
        );
      }

      // Sonraki tarihi hesapla
      final nextDate = meeting.getNextOccurrence(currentDate);
      if (nextDate == null) break;

      currentDate = nextDate;
      occurrenceCount++;
    }

    return createdMeetingIds;
  }

  // Tekrarlayan toplantı serisini güncelle
  Future<void> updateRecurringMeetings(
    String parentMeetingId,
    MeetingModel updatedMeeting,
  ) async {
    // Seri ID'sine sahip tüm toplantıları bul
    final meetings = await _meetingsRef
        .where('parentMeetingId', isEqualTo: parentMeetingId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
        .get();

    // Gelecek toplantıları güncelle
    for (final doc in meetings.docs) {
      final meeting = MeetingModel.fromMap(doc.data());
      final duration = updatedMeeting.endTime.difference(updatedMeeting.startTime);

      final updatedFields = {
        'title': updatedMeeting.title,
        'description': updatedMeeting.description,
        'participants': updatedMeeting.participants.map((p) => p.toMap()).toList(),
        'departments': updatedMeeting.departments,
        'agenda': updatedMeeting.agenda,
        'isOnline': updatedMeeting.isOnline,
        'meetingPlatform': updatedMeeting.meetingPlatform,
        'meetingLink': updatedMeeting.meetingLink,
        'location': updatedMeeting.location,
        'endTime': Timestamp.fromDate(
          meeting.startTime.add(duration),
        ),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      await doc.reference.update(updatedFields);

      // Katılımcılara bildirim gönder
      for (final participant in updatedMeeting.participants) {
        await _notificationService.createNotification(
          title: 'Toplantı Serisi Güncellendi',
          message: '${updatedMeeting.title} toplantı serisinde değişiklik yapıldı.',
          type: NotificationModel.typeMeetingUpdate,
          userId: participant.userId,
          taskId: meeting.id,
          senderId: updatedMeeting.organizerId,
        );
      }
    }
  }

  // Tekrarlayan toplantı serisini iptal et
  Future<void> cancelRecurringMeetings(String parentMeetingId) async {
    final meetings = await _meetingsRef
        .where('parentMeetingId', isEqualTo: parentMeetingId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
        .get();

    for (final doc in meetings.docs) {
      final meeting = MeetingModel.fromMap(doc.data());

      await doc.reference.update({
        'status': MeetingModel.statusCancelled,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Katılımcılara bildirim gönder
      for (final participant in meeting.participants) {
        await _notificationService.createNotification(
          title: 'Toplantı Serisi İptal Edildi',
          message: '${meeting.title} toplantı serisi iptal edildi.',
          type: NotificationModel.typeMeetingCancelled,
          userId: participant.userId,
          taskId: meeting.id,
          senderId: meeting.organizerId,
        );
      }
    }
  }

  // Tekrarlayan toplantı serisinden bir toplantıyı iptal et
  Future<void> cancelSingleOccurrence(String meetingId) async {
    final doc = await _meetingsRef.doc(meetingId).get();
    if (!doc.exists) return;

    final meeting = MeetingModel.fromMap(doc.data()!);

    await doc.reference.update({
      'status': MeetingModel.statusCancelled,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Katılımcılara bildirim gönder
    for (final participant in meeting.participants) {
      await _notificationService.createNotification(
        title: 'Toplantı İptal Edildi',
        message: '${meeting.title} toplantısı iptal edildi.',
        type: NotificationModel.typeMeetingCancelled,
        userId: participant.userId,
        taskId: meetingId,
        senderId: meeting.organizerId,
      );
    }
  }

  // Tekrarlayan toplantı serisinin tüm toplantılarını getir
  Stream<List<MeetingModel>> getRecurringMeetings(String parentMeetingId) {
    return _meetingsRef
        .where('parentMeetingId', isEqualTo: parentMeetingId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
} 