import 'package:cloud_firestore/cloud_firestore.dart';
import '../logging_service.dart';
import 'workflow_service_base.dart';

class WorkflowServiceFiles extends WorkflowServiceBase {
  final FirebaseFirestore _firestore;
  final LoggingService _loggingService;
  final String _collection = 'workflows';

  WorkflowServiceFiles({
    FirebaseFirestore? firestore,
    LoggingService? loggingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _loggingService = loggingService ?? LoggingService(),
       super(
         firestore: firestore ?? FirebaseFirestore.instance,
         loggingService: loggingService ?? LoggingService(),
       );

  // İş akışına dosya ekleme
  Future<void> addFile(
    String workflowId,
    String fileUrl,
    String fileName,
    String uploadedBy,
  ) async {
    try {
      final ref = _firestore.collection(_collection).doc(workflowId);
      
      await ref.update({
        'files': FieldValue.arrayUnion([
          {
            'url': fileUrl,
            'name': fileName,
            'uploadedBy': uploadedBy,
            'uploadedAt': FieldValue.serverTimestamp(),
          }
        ])
      });

      await _loggingService.info(
        'İş akışına dosya eklendi',
        module: 'workflow',
        data: {
          'workflowId': workflowId,
          'fileName': fileName,
          'uploadedBy': uploadedBy,
        },
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışına dosya ekleme hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }

  // İş akışından dosya silme
  Future<void> removeFile(String workflowId, String fileUrl) async {
    try {
      final workflow = await getWorkflow(workflowId);
      final files = List<Map<String, dynamic>>.from(
        workflow.toMap()['files'] ?? [],
      );

      files.removeWhere((file) => file['url'] == fileUrl);

      await _firestore.collection(_collection).doc(workflowId).update({
        'files': files,
      });

      await _loggingService.info(
        'İş akışından dosya silindi',
        module: 'workflow',
        data: {
          'workflowId': workflowId,
          'fileUrl': fileUrl,
        },
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışından dosya silme hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }
}
