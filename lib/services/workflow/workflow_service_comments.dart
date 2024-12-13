import 'package:cloud_firestore/cloud_firestore.dart';
import '../logging_service.dart';
import 'workflow_service_base.dart';

class WorkflowServiceComments extends WorkflowServiceBase {
  final FirebaseFirestore _firestore;
  final LoggingService _loggingService;
  final String _collection = 'workflows';

  WorkflowServiceComments({
    FirebaseFirestore? firestore,
    LoggingService? loggingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _loggingService = loggingService ?? LoggingService(),
       super(
         firestore: firestore ?? FirebaseFirestore.instance,
         loggingService: loggingService ?? LoggingService(),
       );

  // İş akışına yorum ekleme
  Future<void> addComment(String workflowId, String comment, String userId) async {
    try {
      final ref = _firestore
          .collection(_collection)
          .doc(workflowId)
          .collection('comments');

      await ref.add({
        'comment': comment,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _loggingService.info(
        'İş akışına yorum eklendi',
        module: 'workflow',
        data: {
          'workflowId': workflowId,
          'userId': userId,
        },
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışına yorum ekleme hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }

  // İş akışı yorumlarını getirme
  Future<List<Map<String, dynamic>>> getComments(String workflowId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(workflowId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      await _loggingService.error(
        'İş akışı yorumlarını getirme hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }
}
