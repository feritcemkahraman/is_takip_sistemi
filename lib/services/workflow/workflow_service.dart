import 'package:cloud_firestore/cloud_firestore.dart';
import '../logging_service.dart';
import 'workflow_service_base.dart';
import 'workflow_service_steps.dart';
import 'workflow_service_comments.dart';
import 'workflow_service_files.dart';

class WorkflowService implements WorkflowServiceBase {
  final WorkflowServiceBase _base;
  final WorkflowServiceSteps _steps;
  final WorkflowServiceComments _comments;
  final WorkflowServiceFiles _files;

  WorkflowService({
    required FirebaseFirestore firestore,
    required LoggingService loggingService,
  })  : _base = WorkflowServiceBase(
          firestore: firestore,
          loggingService: loggingService,
        ),
        _steps = WorkflowServiceSteps(
          firestore: firestore,
          loggingService: loggingService,
        ),
        _comments = WorkflowServiceComments(
          firestore: firestore,
          loggingService: loggingService,
        ),
        _files = WorkflowServiceFiles(
          firestore: firestore,
          loggingService: loggingService,
        );

  // WorkflowServiceBase metodları
  @override
  Future<String> createWorkflow({
    required String title,
    required String description,
    required List<WorkflowStep> steps,
  }) =>
      _base.createWorkflow(
        title: title,
        description: description,
        steps: steps,
      );

  @override
  Future<WorkflowModel> getWorkflow(String id) => _base.getWorkflow(id);

  @override
  Future<void> updateWorkflow(WorkflowModel workflow) =>
      _base.updateWorkflow(workflow);

  @override
  Future<void> deleteWorkflow(String id) => _base.deleteWorkflow(id);

  @override
  Stream<List<WorkflowModel>> getUserWorkflows(String userId) =>
      _base.getUserWorkflows(userId);

  @override
  Stream<List<WorkflowModel>> getTemplates() => _base.getTemplates();

  @override
  Future<WorkflowModel> createFromTemplate(
    String templateId,
    String userId,
  ) =>
      _base.createFromTemplate(templateId, userId);

  @override
  Stream<List<WorkflowHistory>> getHistory(String workflowId) {
    return _base.getHistory(workflowId);
  }

  // WorkflowServiceSteps metodları
  Future<void> updateWorkflowStep(String workflowId, WorkflowStep step) =>
      _steps.updateWorkflowStep(workflowId, step);

  Future<void> updateStepStatus(
    String workflowId,
    String stepId,
    String newStatus,
  ) =>
      _steps.updateStepStatus(workflowId, stepId, newStatus);

  Future<void> checkAndUpdateWorkflowStatus(String workflowId) =>
      _steps.checkAndUpdateWorkflowStatus(workflowId);

  // WorkflowServiceComments metodları
  Future<void> addComment(
    String workflowId,
    String comment,
    String userId,
  ) =>
      _comments.addComment(workflowId, comment, userId);

  Future<List<Map<String, dynamic>>> getComments(String workflowId) =>
      _comments.getComments(workflowId);

  // WorkflowServiceFiles metodları
  Future<void> addFile(
    String workflowId,
    String fileUrl,
    String fileName,
    String uploadedBy,
  ) =>
      _files.addFile(workflowId, fileUrl, fileName, uploadedBy);

  Future<void> removeFile(String workflowId, String fileUrl) =>
      _files.removeFile(workflowId, fileUrl);
}
