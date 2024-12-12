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
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  // Departman toplantılarını getir
  Stream<List<MeetingModel>> getDepartmentMeetings(String department) {
    return _firestore
        .collection(_collection)
        .where('departments', arrayContains: department)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  // Toplantı notu ekle
  Future<void> addNote(String meetingId, MeetingNote note) async {
    try {
      final meeting = await getMeeting(meetingId);
      final updatedNotes = [...meeting.notes, note];
      
      await _firestore.collection(_collection).doc(meetingId).update({
        'notes': updatedNotes.map((note) => note.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Katılımcılara bildirim gönder
      for (final participantId in meeting.participants) {
        if (participantId != note.createdBy) {
          await _notificationService.createNotification(
            title: 'Yeni Toplantı Notu',
            message: '${meeting.title} toplantısına yeni bir not eklendi',
            type: NotificationModel.typeMeetingNote,
            userId: participantId,
          );
        }
      }
    } catch (e) {
      throw 'Not eklenirken bir hata oluştu: $e';
    }
  }

  // Katılımcı ekle
  Future<void> addParticipant(String meetingId, String userId) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting.participants.contains(userId)) return;

      await _firestore.collection(_collection).doc(meetingId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Yeni katılımcıya bildirim gönder
      await _notificationService.createNotification(
        title: 'Yeni Toplantı Daveti',
        message: '${meeting.title} toplantısına davet edildiniz',
        type: NotificationModel.typeMeetingInvite,
        userId: userId,
      );
    } catch (e) {
      throw 'Katılımcı eklenirken bir hata oluştu: $e';
    }
  }

  // Katılımcı çıkar
  Future<void> removeParticipant(String meetingId, String userId) async {
    try {
      final meeting = await getMeeting(meetingId);
      await _firestore.collection(_collection).doc(meetingId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Çıkarılan katılımcıya bildirim gönder
      await _notificationService.createNotification(
        title: 'Toplantı Bilgisi',
        message: '${meeting.title} toplantısından çıkarıldınız',
        type: NotificationModel.typeMeetingRemoved,
        userId: userId,
      );
    } catch (e) {
      throw 'Katılımcı çıkarılırken bir hata oluştu: $e';
    }
  }

  // Katılım durumunu güncelle
  Future<void> updateAttendance(
    String meetingId,
    String userId,
    bool attended,
  ) async {
    try {
      await _firestore.collection(_collection).doc(meetingId).update({
        'attendance.$userId': attended,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Katılım durumu güncellenirken bir hata oluştu: $e';
    }
  }

  // Gündem maddesi ekle
  Future<void> addAgendaItem(String meetingId, MeetingAgendaItem item) async {
    try {
      final meeting = await getMeeting(meetingId);
      final updatedAgenda = [...meeting.agenda, item];
      
      await _firestore.collection(_collection).doc(meetingId).update({
        'agenda': updatedAgenda.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Katılımcılara bildirim gönder
      for (final participantId in meeting.participants) {
        await _notificationService.createNotification(
          title: 'Yeni Gündem Maddesi',
          message: '${meeting.title} toplantısına yeni bir gündem maddesi eklendi',
          type: NotificationModel.typeMeetingAgenda,
          userId: participantId,
        );
      }
    } catch (e) {
      throw 'Gündem maddesi eklenirken bir hata oluştu: $e';
    }
  }

  // Gündem maddesi güncelle
  Future<void> updateAgendaItem(
    String meetingId,
    MeetingAgendaItem item,
  ) async {
    try {
      final meeting = await getMeeting(meetingId);
      final updatedAgenda = meeting.agenda.map((agendaItem) {
        return agendaItem.id == item.id ? item : agendaItem;
      }).toList();

      await _firestore.collection(_collection).doc(meetingId).update({
        'agenda': updatedAgenda.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Gündem maddesi güncellenirken bir hata oluştu: $e';
    }
  }

  // Toplantı durumunu güncelle
  Future<void> updateStatus(String meetingId, String status) async {
    try {
      final meeting = await getMeeting(meetingId);
      await _firestore.collection(_collection).doc(meetingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Katılımcılara bildirim gönder
      String message;
      switch (status) {
        case MeetingModel.statusOngoing:
          message = '${meeting.title} toplantısı başladı';
          break;
        case MeetingModel.statusCompleted:
          message = '${meeting.title} toplantısı tamamlandı';
          break;
        case MeetingModel.statusCancelled:
          message = '${meeting.title} toplantısı iptal edildi';
          break;
        default:
          message = '${meeting.title} toplantısının durumu güncellendi';
      }

      for (final participantId in meeting.participants) {
        await _notificationService.createNotification(
          title: 'Toplantı Durumu Güncellendi',
          message: message,
          type: NotificationModel.typeMeetingStatus,
          userId: participantId,
        );
      }
    } catch (e) {
      throw 'Toplantı durumu güncellenirken bir hata oluştu: $e';
    }
  }

  // Yaklaşan toplantıları getir
  Stream<List<MeetingModel>> getUpcomingMeetings(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: userId)
        .where('startTime', isGreaterThan: now)
        .where('status', isEqualTo: MeetingModel.statusScheduled)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  // Toplantı hatırlatıcılarını kontrol et
  Future<void> checkMeetingReminders() async {
    try {
      final now = DateTime.now();
      final thirtyMinutesLater = now.add(const Duration(minutes: 30));

      final meetings = await _firestore
          .collection(_collection)
          .where('startTime',
              isGreaterThanOrEqualTo: now,
              isLessThanOrEqualTo: thirtyMinutesLater)
          .where('status', isEqualTo: MeetingModel.statusScheduled)
          .get();

      for (final doc in meetings.docs) {
        final meeting = MeetingModel.fromMap(doc.data());
        for (final participantId in meeting.participants) {
          await _notificationService.createNotification(
            title: 'Toplantı Hatırlatması',
            message:
                '${meeting.title} toplantısı ${meeting.startTime.difference(now).inMinutes} dakika sonra başlayacak',
            type: NotificationModel.typeMeetingReminder,
            userId: participantId,
          );
        }
      }
    } catch (e) {
      print('Toplantı hatırlatıcıları kontrol edilirken hata: $e');
    }
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
      final meetingId = _firestore.collection('meetings').doc().id;
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
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
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
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
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
      'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
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