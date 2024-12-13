import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;

  MeetingService({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  // Toplantı oluşturma
  Future<void> createMeeting(MeetingModel meeting) async {
    try {
      await _firestore.collection('meetings').doc(meeting.id).set(
            meeting.toMap(),
          );

      await _notificationService.sendMeetingInviteNotification(meeting);
    } catch (e) {
      print('Toplantı oluşturma hatası: $e');
      rethrow;
    }
  }

  // Tekrarlı toplantılar oluşturma
  Future<void> createRecurringMeetings(MeetingModel meeting) async {
    try {
      // Ana toplantıyı oluştur
      await createMeeting(meeting);

      // Tekrarlı toplantıları oluştur
      if (meeting.isRecurring) {
        DateTime nextDate = meeting.startTime;
        int occurrenceCount = 0;

        while (!meeting.isRecurrenceEnded(nextDate)) {
          nextDate = meeting.getNextOccurrence(nextDate)!;
          occurrenceCount++;

          if (meeting.recurrenceEndType == MeetingModel.endAfterOccurrences &&
              occurrenceCount >= meeting.recurrenceOccurrences!) {
            break;
          }

          final recurringMeeting = MeetingModel(
            id: '${meeting.id}_${occurrenceCount}',
            title: meeting.title,
            description: meeting.description,
            startTime: nextDate,
            endTime: nextDate.add(meeting.endTime.difference(meeting.startTime)),
            organizerId: meeting.organizerId,
            participants: meeting.participants,
            status: meeting.status,
            isOnline: meeting.isOnline,
            meetingPlatform: meeting.meetingPlatform,
            meetingLink: meeting.meetingLink,
            location: meeting.location,
            isRecurring: false,
            parentMeetingId: meeting.id,
            attachments: meeting.attachments,
            departments: meeting.departments,
            agenda: meeting.agenda,
            reminderEnabled: meeting.reminderEnabled,
            reminderMinutes: meeting.reminderMinutes,
          );

          await createMeeting(recurringMeeting);
        }
      }
    } catch (e) {
      print('Tekrarlı toplantı oluşturma hatası: $e');
      rethrow;
    }
  }

  // Toplantı güncelleme
  Future<void> updateMeeting(MeetingModel meeting) async {
    try {
      await _firestore.collection('meetings').doc(meeting.id).update(
            meeting.toMap(),
          );

      await _notificationService.sendMeetingUpdateNotification(meeting);
    } catch (e) {
      print('Toplantı güncelleme hatası: $e');
      rethrow;
    }
  }

  // Tekrarlı toplantıları güncelleme
  Future<void> updateRecurringMeetings(MeetingModel meeting) async {
    try {
      // Ana toplantıyı güncelle
      await updateMeeting(meeting);

      // Gelecek tekrarlı toplantıları güncelle
      if (meeting.isRecurring && meeting.parentMeetingId == null) {
        final recurringMeetings = await _firestore
            .collection('meetings')
            .where('parentMeetingId', isEqualTo: meeting.id)
            .where('startTime', isGreaterThan: Timestamp.now())
            .get();

        for (final doc in recurringMeetings.docs) {
          final recurringMeeting = MeetingModel.fromMap(doc.data());

          final updatedMeeting = recurringMeeting.copyWith(
            title: meeting.title,
            description: meeting.description,
            isOnline: meeting.isOnline,
            meetingPlatform: meeting.meetingPlatform,
            meetingLink: meeting.meetingLink,
            location: meeting.location,
            participants: meeting.participants,
            departments: meeting.departments,
            agenda: meeting.agenda,
            reminderEnabled: meeting.reminderEnabled,
            reminderMinutes: meeting.reminderMinutes,
          );

          await updateMeeting(updatedMeeting);
        }
      }
    } catch (e) {
      print('Tekrarlı toplantı güncelleme hatası: $e');
      rethrow;
    }
  }

  // Toplantı iptal etme
  Future<void> cancelMeeting(String meetingId) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final cancelledMeeting = meeting.copyWith(
        status: MeetingModel.statusCancelled,
      );

      await _firestore.collection('meetings').doc(meetingId).update(
            cancelledMeeting.toMap(),
          );

      await _notificationService.sendMeetingCancelNotification(cancelledMeeting);
    } catch (e) {
      print('Toplantı iptal hatası: $e');
      rethrow;
    }
  }

  // Tekrarlı toplantıları iptal etme
  Future<void> cancelRecurringMeetings(String meetingId) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      // Ana toplantıyı iptal et
      await cancelMeeting(meetingId);

      // Gelecek tekrarlı toplantıları iptal et
      if (meeting.isRecurring && meeting.parentMeetingId == null) {
        final recurringMeetings = await _firestore
            .collection('meetings')
            .where('parentMeetingId', isEqualTo: meetingId)
            .where('startTime', isGreaterThan: Timestamp.now())
            .get();

        for (final doc in recurringMeetings.docs) {
          await cancelMeeting(doc.id);
        }
      }
    } catch (e) {
      print('Tekrarlı toplantı iptal hatası: $e');
      rethrow;
    }
  }

  // Tek seferlik toplantı iptal etme
  Future<void> cancelSingleOccurrence(String meetingId) async {
    try {
      await cancelMeeting(meetingId);
    } catch (e) {
      print('Tek seferlik toplantı iptal hatası: $e');
      rethrow;
    }
  }

  // Toplantı silme
  Future<void> deleteMeeting(String meetingId) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).delete();
    } catch (e) {
      print('Toplantı silme hatası: $e');
      rethrow;
    }
  }

  // Toplantı getirme
  Future<MeetingModel?> getMeeting(String meetingId) async {
    try {
      final doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) return null;
      return MeetingModel.fromMap(doc.data()!);
    } catch (e) {
      print('Toplantı getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının toplantılarını getirme
  Future<List<MeetingModel>> getUserMeetings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Kullanıcı toplantıları getirme hatası: $e');
      rethrow;
    }
  }

  // Yaklaşan toplantıları getirme
  Future<List<MeetingModel>> getUpcomingMeetings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .where('startTime', isGreaterThan: Timestamp.now())
          .where('status', isEqualTo: MeetingModel.statusScheduled)
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Yaklaşan toplantıları getirme hatası: $e');
      rethrow;
    }
  }

  // Geçmiş toplantıları getirme
  Future<List<MeetingModel>> getPastMeetings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .where('startTime', isLessThan: Timestamp.now())
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Geçmiş toplantıları getirme hatası: $e');
      rethrow;
    }
  }

  // Toplantı katılımcısı ekleme
  Future<void> addParticipant(String meetingId, MeetingParticipant participant) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final updatedParticipants = List<MeetingParticipant>.from(meeting.participants)
        ..add(participant);

      final updatedMeeting = meeting.copyWith(
        participants: updatedParticipants,
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      print('Katılımcı ekleme hatası: $e');
      rethrow;
    }
  }

  // Toplantı katılımcısı çıkarma
  Future<void> removeParticipant(String meetingId, String userId) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final updatedParticipants = List<MeetingParticipant>.from(meeting.participants)
        ..removeWhere((p) => p.userId == userId);

      final updatedMeeting = meeting.copyWith(
        participants: updatedParticipants,
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      print('Katılımcı çıkarma hatası: $e');
      rethrow;
    }
  }

  // Toplantı katılım durumu güncelleme
  Future<void> updateParticipantStatus(
    String meetingId,
    String userId,
    String status,
  ) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final updatedParticipants = List<MeetingParticipant>.from(meeting.participants);
      final participantIndex =
          updatedParticipants.indexWhere((p) => p.userId == userId);

      if (participantIndex != -1) {
        final participant = updatedParticipants[participantIndex];
        updatedParticipants[participantIndex] = MeetingParticipant(
          userId: participant.userId,
          name: participant.name,
          rsvpStatus: status,
          rsvpTime: DateTime.now(),
        );

        final updatedMeeting = meeting.copyWith(
          participants: updatedParticipants,
        );

        await updateMeeting(updatedMeeting);
      }
    } catch (e) {
      print('Katılım durumu güncelleme hatası: $e');
      rethrow;
    }
  }

  // Toplantı tutanağı ekleme
  Future<void> addMeetingMinutes(String meetingId, MeetingMinutes minutes) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'minutes': minutes.toMap(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Toplantı tutanağı ekleme hatası: $e');
      rethrow;
    }
  }

  // Toplantı tutanağı onaylama
  Future<void> approveMeetingMinutes(String meetingId, String userId) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'minutes.approvedBy': userId,
        'minutes.approvedAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Toplantı tutanağı onaylama hatası: $e');
      rethrow;
    }
  }

  // Toplantı kararı ekleme
  Future<void> addDecision(String meetingId, MeetingDecision decision) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final updatedDecisions = List<MeetingDecision>.from(meeting.decisions ?? [])
        ..add(decision);

      final updatedMeeting = meeting.copyWith(
        decisions: updatedDecisions,
      );

      await updateMeeting(updatedMeeting);

      await _notificationService.sendMeetingDecisionNotification(
        updatedMeeting,
        decision,
      );
    } catch (e) {
      print('Karar ekleme hatası: $e');
      rethrow;
    }
  }

  // Toplantı kararı güncelleme
  Future<void> updateDecision(
    String meetingId,
    String decisionId,
    MeetingDecision updatedDecision,
  ) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final decisions = List<MeetingDecision>.from(meeting.decisions ?? []);
      final index = decisions.indexWhere((d) => d.id == decisionId);

      if (index != -1) {
        decisions[index] = updatedDecision;

        final updatedMeeting = meeting.copyWith(
          decisions: decisions,
        );

        await updateMeeting(updatedMeeting);

        await _notificationService.sendMeetingDecisionNotification(
          updatedMeeting,
          updatedDecision,
        );
      }
    } catch (e) {
      print('Karar güncelleme hatası: $e');
      rethrow;
    }
  }

  // Toplantı kararı silme
  Future<void> deleteDecision(String meetingId, String decisionId) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final updatedDecisions = List<MeetingDecision>.from(meeting.decisions ?? [])
        ..removeWhere((d) => d.id == decisionId);

      final updatedMeeting = meeting.copyWith(
        decisions: updatedDecisions,
      );

      await updateMeeting(updatedMeeting);
    } catch (e) {
      print('Karar silme hatası: $e');
      rethrow;
    }
  }

  // Gecikmiş kararları kontrol etme
  Future<void> checkOverdueDecisions() async {
    try {
      final now = DateTime.now();
      final meetings = await _firestore
          .collection('meetings')
          .where('status', isEqualTo: MeetingModel.statusCompleted)
          .get();

      for (final doc in meetings.docs) {
        final meeting = MeetingModel.fromMap(doc.data());
        final overdueDecisions = meeting.decisions?.where((d) =>
                d.status == MeetingDecision.statusPending &&
                d.dueDate != null &&
                d.dueDate!.isBefore(now)) ??
            [];

        for (final decision in overdueDecisions) {
          await _notificationService.sendMeetingDecisionOverdueNotification(
            meeting,
            decision,
          );
        }
      }
    } catch (e) {
      print('Gecikmiş kararları kontrol hatası: $e');
      rethrow;
    }
  }

  // Toplantı hatırlatıcılarını kontrol etme
  Future<void> checkMeetingReminders() async {
    try {
      final now = DateTime.now();
      final meetings = await _firestore
          .collection('meetings')
          .where('status', isEqualTo: MeetingModel.statusScheduled)
          .where('startTime', isGreaterThan: Timestamp.now())
          .get();

      for (final doc in meetings.docs) {
        final meeting = MeetingModel.fromMap(doc.data());
        if (!meeting.reminderEnabled) continue;

        for (final minutes in meeting.reminderMinutes) {
          final reminderTime =
              meeting.startTime.subtract(Duration(minutes: minutes));
          if (now.isAfter(reminderTime) &&
              now.isBefore(reminderTime.add(const Duration(minutes: 1)))) {
            await _notificationService.sendMeetingReminderNotification(meeting);
          }
        }
      }
    } catch (e) {
      print('Toplantı hatırlatıcıları kontrol hatası: $e');
      rethrow;
    }
  }

  // Toplantı istatistiklerini getirme
  Future<Map<String, dynamic>> getMeetingStats(String userId) async {
    try {
      final meetings = await getUserMeetings(userId);
      final now = DateTime.now();

      final stats = {
        'total': meetings.length,
        'upcoming': meetings
            .where((m) =>
                m.startTime.isAfter(now) &&
                m.status == MeetingModel.statusScheduled)
            .length,
        'completed': meetings
            .where((m) => m.status == MeetingModel.statusCompleted)
            .length,
        'cancelled': meetings
            .where((m) => m.status == MeetingModel.statusCancelled)
            .length,
        'online': meetings.where((m) => m.isOnline).length,
        'offline': meetings.where((m) => !m.isOnline).length,
        'recurring': meetings.where((m) => m.isRecurring).length,
        'withDecisions':
            meetings.where((m) => (m.decisions?.isNotEmpty ?? false)).length,
        'withMinutes': meetings.where((m) => m.minutes != null).length,
      };

      return stats;
    } catch (e) {
      print('Toplantı istatistikleri getirme hatası: $e');
      rethrow;
    }
  }
}