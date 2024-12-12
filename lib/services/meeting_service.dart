import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import '../services/notification_service.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> createMeeting(MeetingModel meeting) async {
    try {
      await _firestore.collection('meetings').doc(meeting.id).set(meeting.toMap());
    } catch (e) {
      throw Exception('Toplantı oluşturulurken bir hata oluştu: $e');
    }
  }

  Future<MeetingModel> getMeeting(String meetingId) async {
    try {
      final doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) {
        throw Exception('Toplantı bulunamadı');
      }
      return MeetingModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Toplantı alınırken bir hata oluştu: $e');
    }
  }

  Future<List<MeetingModel>> getUserMeetings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: {'userId': userId})
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı toplantıları alınırken bir hata oluştu: $e');
    }
  }

  Future<void> updateMeeting(MeetingModel meeting) async {
    try {
      await _firestore.collection('meetings').doc(meeting.id).update(meeting.toMap());
    } catch (e) {
      throw Exception('Toplantı güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).delete();
    } catch (e) {
      throw Exception('Toplantı silinirken bir hata oluştu: $e');
    }
  }

  Future<void> addMeetingMinutes(String meetingId, MeetingMinutes minutes) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'minutes': minutes.toMap(),
      });

      final meeting = await getMeeting(meetingId);
      await _notificationService.sendMeetingMinutesAddedNotification(meeting);
    } catch (e) {
      throw Exception('Toplantı tutanağı eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> approveMeetingMinutes(String meetingId, String approverUserId) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'minutes.isApproved': true,
        'minutes.approvedBy': approverUserId,
        'minutes.approvedAt': FieldValue.serverTimestamp(),
      });

      final meeting = await getMeeting(meetingId);
      await _notificationService.sendMeetingMinutesApprovedNotification(meeting);
    } catch (e) {
      throw Exception('Toplantı tutanağı onaylanırken bir hata oluştu: $e');
    }
  }

  Future<void> addMeetingDecision(String meetingId, MeetingDecision decision) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'decisions': FieldValue.arrayUnion([decision.toMap()]),
      });

      final meeting = await getMeeting(meetingId);
      await _notificationService.sendMeetingDecisionAddedNotification(meeting, decision);
    } catch (e) {
      throw Exception('Toplantı kararı eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> updateMeetingDecision(String meetingId, MeetingDecision updatedDecision) async {
    try {
      final meeting = await getMeeting(meetingId);
      final decisions = meeting.decisions.map((d) {
        if (d.id == updatedDecision.id) {
          return updatedDecision;
        }
        return d;
      }).toList();

      await _firestore.collection('meetings').doc(meetingId).update({
        'decisions': decisions.map((d) => d.toMap()).toList(),
      });

      await _notificationService.sendMeetingDecisionUpdatedNotification(meeting, updatedDecision);
    } catch (e) {
      throw Exception('Toplantı kararı güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> completeMeetingDecision(String meetingId, String decisionId) async {
    try {
      final meeting = await getMeeting(meetingId);
      final decisions = meeting.decisions.map((d) {
        if (d.id == decisionId) {
          final completedDecision = MeetingDecision(
            id: d.id,
            content: d.content,
            assignedTo: d.assignedTo,
            dueDate: d.dueDate,
            status: MeetingDecision.statusCompleted,
            createdBy: d.createdBy,
            createdAt: d.createdAt,
            completedAt: DateTime.now(),
            attachments: d.attachments,
            notes: d.notes,
          );

          _notificationService.sendMeetingDecisionCompletedNotification(meeting, completedDecision);
          return completedDecision;
        }
        return d;
      }).toList();

      await _firestore.collection('meetings').doc(meetingId).update({
        'decisions': decisions.map((d) => d.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Toplantı kararı tamamlanırken bir hata oluştu: $e');
    }
  }

  Future<void> cancelMeetingDecision(String meetingId, String decisionId) async {
    try {
      final meeting = await getMeeting(meetingId);
      final decisions = meeting.decisions.map((d) {
        if (d.id == decisionId) {
          final cancelledDecision = MeetingDecision(
            id: d.id,
            content: d.content,
            assignedTo: d.assignedTo,
            dueDate: d.dueDate,
            status: MeetingDecision.statusCancelled,
            createdBy: d.createdBy,
            createdAt: d.createdAt,
            completedAt: null,
            attachments: d.attachments,
            notes: d.notes,
          );

          _notificationService.sendMeetingDecisionCancelledNotification(meeting, cancelledDecision);
          return cancelledDecision;
        }
        return d;
      }).toList();

      await _firestore.collection('meetings').doc(meetingId).update({
        'decisions': decisions.map((d) => d.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Toplantı kararı iptal edilirken bir hata oluştu: $e');
    }
  }

  Future<List<MeetingDecision>> getPendingDecisions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('decisions', arrayContains: {'assignedTo': userId, 'status': MeetingDecision.statusPending})
          .get();

      final List<MeetingDecision> pendingDecisions = [];
      for (var doc in querySnapshot.docs) {
        final meeting = MeetingModel.fromMap(doc.data());
        pendingDecisions.addAll(
          meeting.decisions.where((d) => 
            d.assignedTo == userId && 
            d.status == MeetingDecision.statusPending
          ),
        );
      }

      return pendingDecisions;
    } catch (e) {
      throw Exception('Bekleyen kararlar alınırken bir hata oluştu: $e');
    }
  }

  Future<List<MeetingDecision>> getOverdueDecisions(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('decisions', arrayContains: {'assignedTo': userId, 'status': MeetingDecision.statusPending})
          .get();

      final List<MeetingDecision> overdueDecisions = [];
      for (var doc in querySnapshot.docs) {
        final meeting = MeetingModel.fromMap(doc.data());
        final decisions = meeting.decisions.where((d) => 
          d.assignedTo == userId && 
          d.status == MeetingDecision.statusPending &&
          d.dueDate.isBefore(now)
        );

        for (final decision in decisions) {
          overdueDecisions.add(decision);
          await _notificationService.sendMeetingDecisionOverdueNotification(meeting, decision);
        }
      }

      return overdueDecisions;
    } catch (e) {
      throw Exception('Gecikmiş kararlar alınırken bir hata oluştu: $e');
    }
  }

  // Gecikmiş kararları kontrol et
  Future<void> checkOverdueDecisions() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('decisions', arrayContains: {'status': MeetingDecision.statusPending})
          .get();

      for (var doc in querySnapshot.docs) {
        final meeting = MeetingModel.fromMap(doc.data());
        final overdueDecisions = meeting.decisions.where((d) => 
          d.status == MeetingDecision.statusPending &&
          d.dueDate.isBefore(now)
        );

        for (final decision in overdueDecisions) {
          await _notificationService.sendMeetingDecisionOverdueNotification(
            meeting,
            decision,
          );
        }
      }
    } catch (e) {
      print('Gecikmiş kararlar kontrol edilirken hata: $e');
    }
  }

  // Her gün gecikmiş kararları kontrol et
  void startOverdueDecisionsCheck() {
    const duration = Duration(days: 1);
    Future.doWhile(() async {
      await checkOverdueDecisions();
      await Future.delayed(duration);
      return true; // Sonsuz döngü
    });
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
      if (meeting.isRecurrenceEnded(currentDate)) {
        break;
      }

      // Tekrarlama sayısı kontrolü
      if (meeting.recurrenceEndType == MeetingModel.endAfterOccurrences &&
          meeting.recurrenceOccurrences != null &&
          occurrenceCount >= meeting.recurrenceOccurrences!) {
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
      await _firestore.collection('meetings').doc(meetingId).set(newMeeting.toMap());

      // Katılımcılara bildirim gönder
      for (final participant in meeting.participants) {
        await _notificationService.createNotification(
          title: NotificationModel.getTitle(NotificationModel.typeMeetingInvite),
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
    final meetings = await _firestore
        .collection('meetings')
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
          title: NotificationModel.getTitle(NotificationModel.typeMeetingUpdate),
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
    final meetings = await _firestore
        .collection('meetings')
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
          title: NotificationModel.getTitle(NotificationModel.typeMeetingCancelled),
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
    final doc = await _firestore.collection('meetings').doc(meetingId).get();
    if (!doc.exists) return;

    final meeting = MeetingModel.fromMap(doc.data()!);

    await doc.reference.update({
      'status': MeetingModel.statusCancelled,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Katılımcılara bildirim gönder
    for (final participant in meeting.participants) {
      await _notificationService.createNotification(
        title: NotificationModel.getTitle(NotificationModel.typeMeetingCancelled),
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
    return _firestore
        .collection('meetings')
        .where('parentMeetingId', isEqualTo: parentMeetingId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }
} 