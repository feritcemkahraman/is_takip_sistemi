import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_report_model.dart';
import '../models/meeting_model.dart';

class MeetingReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MeetingReportModel> generateReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    List<String> sharedWith = const [],
  }) async {
    try {
      // Tarih aralığındaki toplantıları getir
      final querySnapshot = await _firestore
          .collection('meetings')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final meetings = querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();

      // Toplantı durumu dağılımı
      final statusDistribution = <String, int>{};
      for (final meeting in meetings) {
        statusDistribution[meeting.status] = (statusDistribution[meeting.status] ?? 0) + 1;
      }

      // Toplantı tipi dağılımı (online/yüz yüze)
      final typeDistribution = <String, int>{
        'online': meetings.where((m) => m.isOnline).length,
        'inPerson': meetings.where((m) => !m.isOnline).length,
      };

      // Departman katılımı
      final departmentParticipation = <String, double>{};
      final departmentMeetings = <String, int>{};
      for (final meeting in meetings) {
        for (final department in meeting.departments) {
          departmentMeetings[department] = (departmentMeetings[department] ?? 0) + 1;
        }
      }
      departmentMeetings.forEach((department, count) {
        departmentParticipation[department] = count / meetings.length;
      });

      // Kullanıcı katılımı
      final userParticipation = <String, int>{};
      for (final meeting in meetings) {
        for (final participant in meeting.participants) {
          if (participant.rsvpStatus == MeetingParticipant.statusAttending) {
            userParticipation[participant.userId] = 
                (userParticipation[participant.userId] ?? 0) + 1;
          }
        }
      }

      // Karar durumu dağılımı
      final decisionStatusDistribution = <String, int>{};
      final decisionAssigneeDistribution = <String, int>{};
      var totalDecisionCompletionTime = 0.0;
      var completedDecisionCount = 0;

      for (final meeting in meetings) {
        for (final decision in meeting.decisions) {
          decisionStatusDistribution[decision.status] = 
              (decisionStatusDistribution[decision.status] ?? 0) + 1;

          if (decision.assignedTo != null) {
            decisionAssigneeDistribution[decision.assignedTo!] = 
                (decisionAssigneeDistribution[decision.assignedTo!] ?? 0) + 1;
          }

          if (decision.status == MeetingDecision.statusCompleted && 
              decision.completedAt != null) {
            totalDecisionCompletionTime += 
                decision.completedAt!.difference(decision.createdAt).inDays;
            completedDecisionCount++;
          }
        }
      }

      // Ortalama toplantı süresi
      var totalDuration = 0.0;
      for (final meeting in meetings) {
        totalDuration += meeting.endTime.difference(meeting.startTime).inMinutes;
      }

      // Zaman çizelgesi verileri
      final timeline = meetings.map((meeting) => {
        'date': meeting.startTime.toIso8601String(),
        'title': meeting.title,
        'type': meeting.isOnline ? 'online' : 'inPerson',
        'status': meeting.status,
        'participantCount': meeting.participants.length,
        'decisionCount': meeting.decisions.length,
      }).toList();

      // Rapor verilerini oluştur
      final reportData = {
        'statusDistribution': statusDistribution,
        'typeDistribution': typeDistribution,
        'departmentParticipation': departmentParticipation,
        'userParticipation': userParticipation,
        'decisionStatusDistribution': decisionStatusDistribution,
        'decisionAssigneeDistribution': decisionAssigneeDistribution,
        'averageDecisionCompletionTime': completedDecisionCount > 0
            ? totalDecisionCompletionTime / completedDecisionCount
            : 0.0,
        'averageMeetingDuration': meetings.isNotEmpty
            ? totalDuration / meetings.length
            : 0.0,
        'totalMeetings': meetings.length,
        'completedMeetings': meetings
            .where((m) => m.status == MeetingModel.statusCompleted)
            .length,
        'cancelledMeetings': meetings
            .where((m) => m.status == MeetingModel.statusCancelled)
            .length,
        'totalDecisions': meetings
            .fold(0, (sum, m) => sum + m.decisions.length),
        'completedDecisions': meetings
            .fold(0, (sum, m) => sum + m.decisions
                .where((d) => d.status == MeetingDecision.statusCompleted)
                .length),
        'overdueDecisions': meetings
            .fold(0, (sum, m) => sum + m.decisions
                .where((d) => 
                    d.status == MeetingDecision.statusPending && 
                    d.dueDate.isBefore(DateTime.now()))
                .length),
        'decisionCompletionRate': completedDecisionCount > 0
            ? completedDecisionCount / meetings
                .fold(0, (sum, m) => sum + m.decisions.length)
            : 0.0,
        'meetingAttendanceRate': meetings.isNotEmpty
            ? meetings.fold(0, (sum, m) => sum + m.participants
                .where((p) => p.rsvpStatus == MeetingParticipant.statusAttending)
                .length) / 
              meetings.fold(0, (sum, m) => sum + m.participants.length)
            : 0.0,
        'timeline': timeline,
      };

      // Raporu oluştur
      final report = MeetingReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        data: reportData,
        sharedWith: sharedWith,
      );

      // Raporu kaydet
      await _firestore
          .collection('meeting_reports')
          .doc(report.id)
          .set(report.toMap());

      return report;
    } catch (e) {
      throw Exception('Rapor oluşturulurken bir hata oluştu: $e');
    }
  }

  Future<List<MeetingReportModel>> getUserReports(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('meeting_reports')
          .where('sharedWith', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Raporlar alınırken bir hata oluştu: $e');
    }
  }

  Future<MeetingReportModel> getReport(String reportId) async {
    try {
      final doc = await _firestore
          .collection('meeting_reports')
          .doc(reportId)
          .get();

      if (!doc.exists) {
        throw Exception('Rapor bulunamadı');
      }

      return MeetingReportModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Rapor alınırken bir hata oluştu: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore
          .collection('meeting_reports')
          .doc(reportId)
          .delete();
    } catch (e) {
      throw Exception('Rapor silinirken bir hata oluştu: $e');
    }
  }

  Future<void> shareReport(String reportId, List<String> userIds) async {
    try {
      await _firestore
          .collection('meeting_reports')
          .doc(reportId)
          .update({
        'sharedWith': FieldValue.arrayUnion(userIds),
      });
    } catch (e) {
      throw Exception('Rapor paylaşılırken bir hata oluştu: $e');
    }
  }

  Future<void> unshareReport(String reportId, List<String> userIds) async {
    try {
      await _firestore
          .collection('meeting_reports')
          .doc(reportId)
          .update({
        'sharedWith': FieldValue.arrayRemove(userIds),
      });
    } catch (e) {
      throw Exception('Rapor paylaşımı kaldırılırken bir hata oluştu: $e');
    }
  }
} 