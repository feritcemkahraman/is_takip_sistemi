import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workflow_model.dart';
import '../../models/workflow_history.dart';
import '../logging_service.dart';
import 'package:uuid/uuid.dart';

class WorkflowServiceBase {
  final FirebaseFirestore _firestore;
  final LoggingService _loggingService;
  final String _collection = 'workflows';

  WorkflowServiceBase({
    FirebaseFirestore? firestore,
    LoggingService? loggingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _loggingService = loggingService ?? LoggingService();

  // İş akışı oluşturma
  Future<String> createWorkflow({
    required String title,
    required String description,
    required String type,
    required int priority,
    required DateTime deadline,
    required List<WorkflowStep> steps,
    required String createdBy,
    required String assignedTo,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'title': title,
        'description': description,
        'type': type,
        'priority': priority,
        'deadline': Timestamp.fromDate(deadline),
        'status': WorkflowModel.statusPending,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'assignedTo': assignedTo,
        'steps': steps.map((step) => step.toMap()).toList(),
      });

      await _loggingService.info(
        'İş akışı oluşturuldu',
        module: 'workflow',
        data: WorkflowModel.fromFirestore(await _firestore.collection(_collection).doc(docRef.id).get()).toMap(),
      );

      return docRef.id;
    } catch (e) {
      await _loggingService.error(
        'İş akışı oluşturma hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // İş akışı getir
  Future<WorkflowModel> getWorkflow(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('İş akışı bulunamadı');
      }
      return WorkflowModel.fromFirestore(doc);
    } catch (e) {
      await _loggingService.error(
        'İş akışı getirme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // İş akışı güncelle
  Future<void> updateWorkflow(WorkflowModel workflow) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(workflow.id)
          .update(workflow.toMap());

      await _loggingService.info(
        'İş akışı güncellendi',
        module: 'workflow',
        data: workflow.toMap(),
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışı güncelleme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // İş akışı sil
  Future<void> deleteWorkflow(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();

      await _loggingService.info(
        'İş akışı silindi',
        module: 'workflow',
        data: {'workflowId': id},
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışı silme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // Kullanıcının iş akışlarını getir
  Stream<List<WorkflowModel>> getUserWorkflows(String userId) async* {
    try {
      yield* _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => WorkflowModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      await _loggingService.error(
        'Kullanıcı iş akışları getirme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      yield [];
    }
  }

  // İş akışı geçmişini getir
  Stream<List<WorkflowHistory>> getHistory(String workflowId) async* {
    try {
      yield* _firestore
          .collection(_collection)
          .doc(workflowId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return WorkflowHistory(
                  id: doc.id,
                  workflowId: workflowId,
                  action: data['action'] as String,
                  userId: data['userId'] as String,
                  details: data['details'] as String?,
                  timestamp: (data['timestamp'] as Timestamp).toDate(),
                );
              })
              .toList());
    } catch (e) {
      await _loggingService.error(
        'İş akışı geçmişi getirme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      yield [];
    }
  }

  // İş akışı şablonlarını getir
  Stream<List<WorkflowModel>> getTemplates() async* {
    try {
      yield* _firestore
          .collection('workflow_templates')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => WorkflowModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      await _loggingService.error(
        'İş akışı şablonları getirme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      yield [];
    }
  }

  // Şablondan iş akışı oluştur
  Future<String> createFromTemplate(
    String templateId,
    String createdBy,
    String assignedTo,
  ) async {
    try {
      final template = await _firestore
          .collection('workflow_templates')
          .doc(templateId)
          .get();

      if (!template.exists) {
        throw Exception('Şablon bulunamadı');
      }

      final data = template.data()!;
      final workflowId = const Uuid().v4();

      await _firestore.collection(_collection).doc(workflowId).set({
        ...data,
        'createdBy': createdBy,
        'assignedTo': assignedTo,
        'createdAt': FieldValue.serverTimestamp(),
        'status': WorkflowModel.statusPending,
      });

      await _loggingService.info(
        'Şablondan iş akışı oluşturuldu',
        module: 'workflow',
        data: WorkflowModel.fromFirestore(await _firestore.collection(_collection).doc(workflowId).get()).toMap(),
      );

      return workflowId;
    } catch (e) {
      await _loggingService.error(
        'Şablondan iş akışı oluşturma hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // İş akışı adımını güncelle
  Future<void> updateWorkflowStep(String workflowId, WorkflowStep step) async {
    try {
      final workflow = await getWorkflow(workflowId);
      final steps = workflow.steps.map((s) {
        if (s.id == step.id) {
          return step;
        }
        return s;
      }).toList();

      await _firestore.collection(_collection).doc(workflowId).update({
        'steps': steps.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loggingService.info(
        'İş akışı adımı güncellendi',
        module: 'workflow',
        data: step.toMap(),
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışı adımı güncelleme hatası',
        module: 'workflow',
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }
}
