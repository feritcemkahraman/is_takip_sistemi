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
} 