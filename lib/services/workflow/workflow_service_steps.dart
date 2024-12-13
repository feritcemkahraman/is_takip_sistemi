import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workflow_model.dart';
import '../logging_service.dart';
import 'workflow_service_base.dart';

class WorkflowServiceSteps extends WorkflowServiceBase {
  final FirebaseFirestore _firestore;
  final LoggingService _loggingService;

  WorkflowServiceSteps({
    FirebaseFirestore? firestore,
    LoggingService? loggingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _loggingService = loggingService ?? LoggingService(),
       super(
         firestore: firestore ?? FirebaseFirestore.instance,
         loggingService: loggingService ?? LoggingService(),
       );

  // İş akışı adımını güncelleme
  Future<void> updateWorkflowStep(String workflowId, WorkflowStep step) async {
    try {
      final workflow = await getWorkflow(workflowId);
      final updatedSteps = workflow.steps.map((s) {
        return s.id == step.id ? step : s;
      }).toList();

      await updateWorkflow(
        workflow.copyWith(steps: updatedSteps),
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışı adımı güncelleme hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }

  // İş akışı adımının durumunu güncelleme
  Future<void> updateStepStatus(String workflowId, String stepId, String newStatus) async {
    try {
      final workflow = await getWorkflow(workflowId);
      final step = workflow.steps.firstWhere((s) => s.id == stepId);
      
      final updatedStep = step.copyWith(
        status: newStatus,
        completedAt: newStatus == WorkflowStep.statusCompleted ? DateTime.now() : null,
      );

      await updateWorkflowStep(workflowId, updatedStep);

      await _loggingService.info(
        'İş akışı adımı durumu güncellendi',
        module: 'workflow',
        data: {
          'workflowId': workflowId,
          'stepId': stepId,
          'newStatus': newStatus,
        },
      );
    } catch (e) {
      await _loggingService.error(
        'İş akışı adımı durumu güncelleme hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }

  // İş akışı durumunu kontrol etme ve güncelleme
  Future<void> checkAndUpdateWorkflowStatus(String workflowId) async {
    try {
      final workflow = await getWorkflow(workflowId);
      
      // Tüm adımlar tamamlandıysa
      if (workflow.steps.every((step) => step.status == WorkflowStep.statusCompleted)) {
        await updateWorkflow(
          workflow.copyWith(status: WorkflowModel.statusCompleted),
        );
      }
      // Herhangi bir adım reddedildiyse
      else if (workflow.steps.any((step) => step.status == WorkflowStep.statusRejected)) {
        await updateWorkflow(
          workflow.copyWith(status: WorkflowModel.statusRejected),
        );
      }
      // En az bir adım devam ediyorsa
      else if (workflow.steps.any((step) => step.status == WorkflowStep.statusActive)) {
        await updateWorkflow(
          workflow.copyWith(status: WorkflowModel.statusInProgress),
        );
      }
    } catch (e) {
      await _loggingService.error(
        'İş akışı durumu kontrol hatası',
        module: 'workflow',
        error: e,
      );
      rethrow;
    }
  }
}
