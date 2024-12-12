import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workflow_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class WorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();
  
  // Cache için
  final Map<String, WorkflowModel> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  Timer? _cacheCleanupTimer;

  WorkflowService() {
    // Cache temizleme zamanlayıcısı
    _cacheCleanupTimer = Timer.periodic(_cacheDuration, (_) => _cleanCache());
  }

  // Cache temizleme
  void _cleanCache() {
    _cache.clear();
  }

  // İş akışı oluşturma
  Future<WorkflowModel> createWorkflow(WorkflowModel workflow) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflow.id);
      
      // İş akışını kaydet
      batch.set(docRef, workflow.toMap());

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'created',
        userId: workflow.createdBy,
        timestamp: DateTime.now(),
        data: {'status': workflow.status},
      ).toMap());

      // İlk adım için bildirim
      if (workflow.steps.isNotEmpty) {
        final firstStep = workflow.steps.first;
        await _notificationService.createNotification(
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Yeni İş Akışı Görevi',
            body: '${workflow.title} iş akışında yeni bir göreviniz var',
            type: NotificationModel.typeWorkflow,
            userId: firstStep.assignedTo,
            data: {
              'workflowId': workflow.id,
              'stepId': firstStep.id,
            },
            createdAt: DateTime.now(),
          ),
        );
      }

      await batch.commit();
      _cache[workflow.id] = workflow;
      return workflow;
    } catch (e) {
      print('İş akışı oluşturma hatası: $e');
      rethrow;
    }
  }

  // Şablon oluşturma
  Future<WorkflowModel> createTemplate(WorkflowModel template) async {
    if (!template.isTemplate) {
      throw Exception('Şablon olarak işaretlenmemiş');
    }
    final docRef = _firestore.collection('workflow_templates').doc(template.id);
    await docRef.set(template.toMap());
    return template;
  }

  // Şablondan iş akışı oluşturma
  Future<WorkflowModel> createFromTemplate(String templateId, String userId, {
    Map<String, dynamic>? data,
  }) async {
    final templateDoc = await _firestore
        .collection('workflow_templates')
        .doc(templateId)
        .get();

    if (!templateDoc.exists) {
      throw Exception('Şablon bulunamadı');
    }

    final template = WorkflowModel.fromMap(templateDoc.data()!);
    final newWorkflow = template.createFromTemplate(
      newId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      newData: data,
    );

    return await createWorkflow(newWorkflow);
  }

  // İş akışı güncelleme
  Future<void> updateWorkflow(WorkflowModel workflow) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflow.id);
      
      // İş akışını güncelle
      batch.update(docRef, workflow.toMap());

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'updated',
        userId: workflow.createdBy,
        timestamp: DateTime.now(),
        data: {'status': workflow.status},
      ).toMap());

      await batch.commit();
      _cache[workflow.id] = workflow;
    } catch (e) {
      print('İş akışı güncelleme hatası: $e');
      rethrow;
    }
  }

  // İş akışı silme
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      // Dosyaları sil
      final workflow = await getWorkflow(workflowId);
      if (workflow != null) {
        for (final file in workflow.files) {
          await _storageService.deleteFile(file.url);
        }
      }

      // Alt koleksiyonları sil
      final collections = ['history', 'comments'];
      for (final collection in collections) {
        final querySnapshot = await docRef.collection(collection).get();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // İş akışını sil
      batch.delete(docRef);

      await batch.commit();
      _cache.remove(workflowId);
    } catch (e) {
      print('İş akışı silme hatası: $e');
      rethrow;
    }
  }

  // İş akışı getirme
  Future<WorkflowModel?> getWorkflow(String workflowId) async {
    try {
      // Cache kontrolü
      if (_cache.containsKey(workflowId)) {
        return _cache[workflowId];
      }

      final doc = await _firestore.collection('workflows').doc(workflowId).get();
      if (!doc.exists) return null;

      final workflow = WorkflowModel.fromMap(doc.data()!);
      _cache[workflowId] = workflow;
      return workflow;
    } catch (e) {
      print('İş akışı getirme hatası: $e');
      rethrow;
    }
  }

  // Şablon getirme
  Future<WorkflowModel?> getTemplate(String templateId) async {
    final doc = await _firestore
        .collection('workflow_templates')
        .doc(templateId)
        .get();
    if (!doc.exists) return null;
    return WorkflowModel.fromMap(doc.data()!);
  }

  // Kullanıcının iş akışlarını getirme
  Stream<List<WorkflowModel>> getUserWorkflows(
    String userId, {
    String? status,
    String? type,
    int? priority,
    bool? isActive,
    String? sortBy,
    bool descending = true,
  }) {
    Query query = _firestore
        .collection('workflows')
        .where('steps', arrayContains: {'assignedTo': userId});

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (priority != null) {
      query = query.where('priority', isEqualTo: priority);
    }
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (sortBy != null) {
      query = query.orderBy(sortBy, descending: descending);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => WorkflowModel.fromMap(doc.data()))
        .toList());
  }

  // Şablonları getirme
  Stream<List<WorkflowModel>> getTemplates() {
    return _firestore
        .collection('workflow_templates')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkflowModel.fromMap(doc.data()))
            .toList());
  }

  // Adım durumunu güncelleme
  Future<void> updateStepStatus(
    String workflowId,
    String stepId,
    String newStatus, {
    Map<String, dynamic>? data,
  }) async {
    final workflow = await getWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('İş akışı bulunamadı');
    }

    final stepIndex =
        workflow.steps.indexWhere((step) => step.id == stepId);
    if (stepIndex == -1) {
      throw Exception('Adım bulunamadı');
    }

    final updatedSteps = List<WorkflowStep>.from(workflow.steps);
    final currentStep = updatedSteps[stepIndex];
    
    updatedSteps[stepIndex] = currentStep.copyWith(
      status: newStatus,
      completedAt: newStatus == WorkflowStep.statusCompleted ? DateTime.now() : null,
      data: data ?? currentStep.data,
    );

    // Sonraki adımı aktifleştir
    if (newStatus == WorkflowStep.statusCompleted && stepIndex < updatedSteps.length - 1) {
      updatedSteps[stepIndex + 1] = updatedSteps[stepIndex + 1].copyWith(
        status: WorkflowStep.statusActive,
        assignedAt: DateTime.now(),
      );

      // Sonraki adım için bildirim gönder
      final nextStep = updatedSteps[stepIndex + 1];
      await _notificationService.createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Yeni İş Akışı Görevi',
          body: '${workflow.title} iş akışında yeni bir göreviniz var: ${nextStep.title}',
          type: NotificationModel.typeWorkflow,
          userId: nextStep.assignedTo,
          data: {
            'workflowId': workflowId,
            'stepId': nextStep.id,
          },
          createdAt: DateTime.now(),
        ),
      );
    }

    // İş akışı durumunu güncelle
    String workflowStatus = workflow.status;
    if (newStatus == WorkflowStep.statusCompleted &&
        updatedSteps.every((step) => step.isCompleted)) {
      workflowStatus = WorkflowModel.statusCompleted;
    } else if (newStatus == WorkflowStep.statusRejected) {
      workflowStatus = WorkflowModel.statusCancelled;
    }

    final updatedWorkflow = WorkflowModel(
      id: workflow.id,
      title: workflow.title,
      description: workflow.description,
      type: workflow.type,
      status: workflowStatus,
      createdBy: workflow.createdBy,
      createdAt: workflow.createdAt,
      steps: updatedSteps,
      data: workflow.data,
      isTemplate: workflow.isTemplate,
      isActive: workflow.isActive,
    );

    await updateWorkflow(updatedWorkflow);
  }

  // Varsayılan şablonları oluştur
  Future<void> createDefaultTemplates(String userId) async {
    // İzin talebi şablonu
    final leaveRequest = WorkflowModel(
      id: 'template_leave_request',
      title: 'İzin Talebi',
      description: 'Çalışan izin talep süreci',
      type: WorkflowModel.typeApproval,
      status: WorkflowModel.statusDraft,
      createdBy: userId,
      createdAt: DateTime.now(),
      steps: [
        WorkflowStep(
          id: '1',
          title: 'Departman Yöneticisi Onayı',
          description: 'Departman yöneticisinin izin talebini onaylaması',
          type: WorkflowStep.typeApproval,
          status: WorkflowStep.statusPending,
          assignedTo: 'manager',
          data: {'level': 1},
        ),
        WorkflowStep(
          id: '2',
          title: 'İK Onayı',
          description: 'İnsan kaynakları departmanının izin talebini onaylaması',
          type: WorkflowStep.typeApproval,
          status: WorkflowStep.statusPending,
          assignedTo: 'hr',
          data: {'level': 2},
        ),
        WorkflowStep(
          id: '3',
          title: 'Bildirim',
          description: 'Çalışana onay durumunun bildirilmesi',
          type: WorkflowStep.typeNotification,
          status: WorkflowStep.statusPending,
          assignedTo: 'system',
          data: {'notificationType': 'email'},
        ),
      ],
      isTemplate: true,
    );

    // Satın alma talebi şablonu
    final purchaseRequest = WorkflowModel(
      id: 'template_purchase_request',
      title: 'Satın Alma Talebi',
      description: 'Satın alma talep süreci',
      type: WorkflowModel.typeApproval,
      status: WorkflowModel.statusDraft,
      createdBy: userId,
      createdAt: DateTime.now(),
      steps: [
        WorkflowStep(
          id: '1',
          title: 'Bütçe Kontrolü',
          description: 'Talep edilen ürünün bütçe kontrolü',
          type: WorkflowStep.typeTask,
          status: WorkflowStep.statusPending,
          assignedTo: 'finance',
          data: {'checkType': 'budget'},
        ),
        WorkflowStep(
          id: '2',
          title: 'Yönetici Onayı',
          description: 'Departman yöneticisinin satın alma talebini onaylaması',
          type: WorkflowStep.typeApproval,
          status: WorkflowStep.statusPending,
          assignedTo: 'manager',
          data: {'level': 1},
        ),
        WorkflowStep(
          id: '3',
          title: 'Satın Alma',
          description: 'Satın alma departmanının siparişi olu��turması',
          type: WorkflowStep.typeTask,
          status: WorkflowStep.statusPending,
          assignedTo: 'purchasing',
          data: {'taskType': 'order'},
        ),
      ],
      isTemplate: true,
    );

    await createTemplate(leaveRequest);
    await createTemplate(purchaseRequest);
  }

  // Yorum ekleme
  Future<void> addComment(
    String workflowId,
    String userId,
    String text, {
    List<String> attachments = const [],
  }) async {
    try {
      final comment = WorkflowComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        userId: userId,
        timestamp: DateTime.now(),
        attachments: attachments,
      );

      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      // Yorumu ekle
      batch.update(docRef, {
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'comment_added',
        userId: userId,
        timestamp: DateTime.now(),
        data: {'commentId': comment.id},
      ).toMap());

      await batch.commit();
      _cache.remove(workflowId);
    } catch (e) {
      print('Yorum ekleme hatası: $e');
      rethrow;
    }
  }

  // Dosya ekleme
  Future<void> addFile(
    String workflowId,
    String userId,
    String filePath,
    String fileName,
  ) async {
    try {
      // Dosyayı yükle
      final url = await _storageService.uploadFile(
        filePath,
        'workflows/$workflowId/files/$fileName',
      );

      final file = WorkflowFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        url: url,
        type: fileName.split('.').last,
        size: await File(filePath).length(),
        uploadedBy: userId,
        uploadedAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      // Dosyayı ekle
      batch.update(docRef, {
        'files': FieldValue.arrayUnion([file.toMap()]),
      });

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'file_added',
        userId: userId,
        timestamp: DateTime.now(),
        data: {'fileId': file.id},
      ).toMap());

      await batch.commit();
      _cache.remove(workflowId);
    } catch (e) {
      print('Dosya ekleme hatası: $e');
      rethrow;
    }
  }

  // Geçmiş getirme
  Stream<List<WorkflowHistory>> getHistory(String workflowId) {
    return _firestore
        .collection('workflows')
        .doc(workflowId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkflowHistory.fromMap(doc.data()))
            .toList());
  }

  // İstatistikler
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('workflows')
          .where('steps', arrayContains: {'assignedTo': userId})
          .get();

      final workflows = querySnapshot.docs
          .map((doc) => WorkflowModel.fromMap(doc.data()))
          .toList();

      return {
        'total': workflows.length,
        'completed': workflows.where((w) => w.isCompleted).length,
        'active': workflows.where((w) => !w.isCompleted && !w.isCancelled).length,
        'overdue': workflows.where((w) => w.isOverdue).length,
        'byType': _groupBy(workflows, (w) => w.type),
        'byPriority': _groupBy(workflows, (w) => w.priority.toString()),
        'byStatus': _groupBy(workflows, (w) => w.status),
      };
    } catch (e) {
      print('İstatistik getirme hatası: $e');
      rethrow;
    }
  }

  Map<String, int> _groupBy(List<WorkflowModel> workflows, String Function(WorkflowModel) fn) {
    return workflows.fold<Map<String, int>>({}, (map, workflow) {
      final key = fn(workflow);
      map[key] = (map[key] ?? 0) + 1;
      return map;
    });
  }

  // Koşullu adım oluşturma
  Future<void> createConditionalStep(
    String workflowId,
    String stepId,
    Map<String, dynamic> conditions,
    List<String> trueStepIds,
    List<String> falseStepIds,
  ) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      // Koşul bilgilerini ekle
      batch.update(docRef, {
        'steps.$stepId.conditions': conditions,
        'steps.$stepId.trueSteps': trueStepIds,
        'steps.$stepId.falseSteps': falseStepIds,
        'steps.$stepId.type': WorkflowStep.typeCondition,
      });

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'condition_added',
        userId: conditions['createdBy'],
        timestamp: DateTime.now(),
        data: {
          'stepId': stepId,
          'conditions': conditions,
        },
      ).toMap());

      await batch.commit();
      _cache.remove(workflowId);
    } catch (e) {
      print('Koşullu adım oluşturma hatası: $e');
      rethrow;
    }
  }

  // Paralel adım oluşturma
  Future<void> createParallelSteps(
    String workflowId,
    String parentStepId,
    List<WorkflowStep> parallelSteps,
  ) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      // Paralel adımları ekle
      batch.update(docRef, {
        'steps.$parentStepId.type': WorkflowStep.typeParallel,
        'steps.$parentStepId.parallelSteps': parallelSteps.map((step) => step.toMap()).toList(),
      });

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'parallel_steps_added',
        userId: parallelSteps.first.assignedTo,
        timestamp: DateTime.now(),
        data: {
          'parentStepId': parentStepId,
          'stepCount': parallelSteps.length,
        },
      ).toMap());

      await batch.commit();
      _cache.remove(workflowId);
    } catch (e) {
      print('Paralel adım oluşturma hatası: $e');
      rethrow;
    }
  }

  // Döngü adımı oluşturma
  Future<void> createLoopStep(
    String workflowId,
    String stepId,
    Map<String, dynamic> loopCondition,
    List<WorkflowStep> loopSteps,
  ) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      // Döngü bilgilerini ekle
      batch.update(docRef, {
        'steps.$stepId.type': WorkflowStep.typeLoop,
        'steps.$stepId.loopCondition': loopCondition,
        'steps.$stepId.loopSteps': loopSteps.map((step) => step.toMap()).toList(),
      });

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'loop_added',
        userId: loopSteps.first.assignedTo,
        timestamp: DateTime.now(),
        data: {
          'stepId': stepId,
          'condition': loopCondition,
        },
      ).toMap());

      await batch.commit();
      _cache.remove(workflowId);
    } catch (e) {
      print('Döngü adımı oluşturma hatası: $e');
      rethrow;
    }
  }

  // Koşul değerlendirme
  Future<bool> evaluateCondition(
    String workflowId,
    String stepId,
    Map<String, dynamic> data,
  ) async {
    try {
      final workflow = await getWorkflow(workflowId);
      if (workflow == null) throw Exception('İş akışı bulunamadı');

      final step = workflow.steps.firstWhere((s) => s.id == stepId);
      if (step.type != WorkflowStep.typeCondition) {
        throw Exception('Bu adım bir koşul adımı değil');
      }

      final conditions = step.conditions;
      if (conditions == null) throw Exception('Koşul tanımlanmamış');

      // Koşulu değerlendir
      bool result = false;
      switch (conditions['type']) {
        case 'equals':
          result = data[conditions['field']] == conditions['value'];
          break;
        case 'notEquals':
          result = data[conditions['field']] != conditions['value'];
          break;
        case 'greaterThan':
          result = data[conditions['field']] > conditions['value'];
          break;
        case 'lessThan':
          result = data[conditions['field']] < conditions['value'];
          break;
        case 'contains':
          result = data[conditions['field']].contains(conditions['value']);
          break;
        case 'expression':
          // TODO: Karmaşık ifadeleri değerlendir
          break;
      }

      // Sonucu kaydet
      final batch = _firestore.batch();
      final docRef = _firestore.collection('workflows').doc(workflowId);
      
      batch.update(docRef, {
        'steps.$stepId.evaluationResult': result,
        'steps.$stepId.evaluationData': data,
      });

      // Geçmiş kaydı ekle
      final historyRef = docRef.collection('history').doc();
      batch.set(historyRef, WorkflowHistory(
        id: historyRef.id,
        action: 'condition_evaluated',
        userId: step.assignedTo,
        timestamp: DateTime.now(),
        data: {
          'stepId': stepId,
          'result': result,
          'data': data,
        },
      ).toMap());

      await batch.commit();
      _cache.remove(workflowId);

      return result;
    } catch (e) {
      print('Koşul değerlendirme hatası: $e');
      rethrow;
    }
  }

  // Paralel adımları kontrol et
  Future<bool> checkParallelSteps(String workflowId, String parentStepId) async {
    try {
      final workflow = await getWorkflow(workflowId);
      if (workflow == null) throw Exception('İş akışı bulunamadı');

      final parentStep = workflow.steps.firstWhere((s) => s.id == parentStepId);
      if (parentStep.type != WorkflowStep.typeParallel) {
        throw Exception('Bu adım bir paralel adım değil');
      }

      final parallelSteps = parentStep.parallelSteps;
      if (parallelSteps == null || parallelSteps.isEmpty) {
        throw Exception('Paralel adım bulunamadı');
      }

      // Tüm paralel adımların tamamlanıp tamamlanmadığını kontrol et
      final allCompleted = parallelSteps.every((step) => step.isCompleted);
      if (allCompleted) {
        // Ana adımı tamamla
        final batch = _firestore.batch();
        final docRef = _firestore.collection('workflows').doc(workflowId);
        
        batch.update(docRef, {
          'steps.$parentStepId.status': WorkflowStep.statusCompleted,
        });

        // Geçmiş kaydı ekle
        final historyRef = docRef.collection('history').doc();
        batch.set(historyRef, WorkflowHistory(
          id: historyRef.id,
          action: 'parallel_steps_completed',
          userId: parentStep.assignedTo,
          timestamp: DateTime.now(),
          data: {
            'parentStepId': parentStepId,
          },
        ).toMap());

        await batch.commit();
        _cache.remove(workflowId);
      }

      return allCompleted;
    } catch (e) {
      print('Paralel adım kontrolü hatası: $e');
      rethrow;
    }
  }

  // Döngü kontrolü
  Future<bool> checkLoopCondition(
    String workflowId,
    String stepId,
    Map<String, dynamic> data,
  ) async {
    try {
      final workflow = await getWorkflow(workflowId);
      if (workflow == null) throw Exception('İş akışı bulunamadı');

      final step = workflow.steps.firstWhere((s) => s.id == stepId);
      if (step.type != WorkflowStep.typeLoop) {
        throw Exception('Bu adım bir döngü adımı değil');
      }

      final loopCondition = step.loopCondition;
      if (loopCondition == null) throw Exception('Döngü koşulu tanımlanmamış');

      // Döngü koşulunu değerlendir
      bool shouldContinue = false;
      switch (loopCondition['type']) {
        case 'count':
          final currentCount = data['currentCount'] ?? 0;
          final maxCount = loopCondition['maxCount'];
          shouldContinue = currentCount < maxCount;
          break;
        case 'condition':
          shouldContinue = await evaluateCondition(
            workflowId,
            stepId,
            loopCondition['condition'],
          );
          break;
      }

      if (!shouldContinue) {
        // Döngüyü tamamla
        final batch = _firestore.batch();
        final docRef = _firestore.collection('workflows').doc(workflowId);
        
        batch.update(docRef, {
          'steps.$stepId.status': WorkflowStep.statusCompleted,
        });

        // Geçmiş kaydı ekle
        final historyRef = docRef.collection('history').doc();
        batch.set(historyRef, WorkflowHistory(
          id: historyRef.id,
          action: 'loop_completed',
          userId: step.assignedTo,
          timestamp: DateTime.now(),
          data: {
            'stepId': stepId,
            'iterations': data['currentCount'],
          },
        ).toMap());

        await batch.commit();
        _cache.remove(workflowId);
      }

      return shouldContinue;
    } catch (e) {
      print('Döngü kontrolü hatası: $e');
      rethrow;
    }
  }

  void dispose() {
    _cacheCleanupTimer?.cancel();
    _cache.clear();
  }
} 