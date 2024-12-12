import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> data;
  final bool isTemplate;
  final bool isActive;
  final int priority;
  final DateTime? deadline;
  final List<WorkflowHistory> history;
  final List<WorkflowComment> comments;
  final List<WorkflowFile> files;

  WorkflowModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.steps,
    this.data = const {},
    this.isTemplate = false,
    this.isActive = true,
    this.priority = 1,
    this.deadline,
    this.history = const [],
    this.comments = const [],
    this.files = const [],
  });

  // İş akışı tipleri
  static const String typeApproval = 'approval';
  static const String typeTask = 'task';
  static const String typeDocument = 'document';
  static const String typeRequest = 'request';

  // İş akışı durumları
  static const String statusDraft = 'draft';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusOverdue = 'overdue';
  static const String statusOnHold = 'on_hold';

  // Öncelik seviyeleri
  static const int priorityLow = 0;
  static const int priorityNormal = 1;
  static const int priorityHigh = 2;
  static const int priorityUrgent = 3;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'steps': steps.map((step) => step.toMap()).toList(),
      'data': data,
      'isTemplate': isTemplate,
      'isActive': isActive,
      'priority': priority,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'history': history.map((item) => item.toMap()).toList(),
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'files': files.map((file) => file.toMap()).toList(),
    };
  }

  factory WorkflowModel.fromMap(Map<String, dynamic> map) {
    return WorkflowModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      steps: (map['steps'] as List<dynamic>)
          .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      data: Map<String, dynamic>.from(map['data'] as Map),
      isTemplate: map['isTemplate'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      priority: map['priority'] as int? ?? 1,
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      history: (map['history'] as List<dynamic>?)
          ?.map((item) => WorkflowHistory.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      comments: (map['comments'] as List<dynamic>?)
          ?.map((comment) => WorkflowComment.fromMap(comment as Map<String, dynamic>))
          .toList() ?? [],
      files: (map['files'] as List<dynamic>?)
          ?.map((file) => WorkflowFile.fromMap(file as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  // Şablon oluştur
  WorkflowModel copyAsTemplate({
    String? newId,
    String? newTitle,
    String? newDescription,
  }) {
    return WorkflowModel(
      id: newId ?? 'template_${DateTime.now().millisecondsSinceEpoch}',
      title: newTitle ?? 'Şablon: $title',
      description: newDescription ?? description,
      type: type,
      status: statusDraft,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      steps: steps.map((step) => step.copyWith()).toList(),
      data: Map<String, dynamic>.from(data),
      isTemplate: true,
      isActive: true,
    );
  }

  // Şablondan iş akışı oluştur
  WorkflowModel createFromTemplate({
    required String newId,
    required String userId,
    Map<String, dynamic>? newData,
  }) {
    if (!isTemplate) {
      throw Exception('Bu bir şablon değil');
    }

    return WorkflowModel(
      id: newId,
      title: title.replaceAll('Şablon: ', ''),
      description: description,
      type: type,
      status: statusActive,
      createdBy: userId,
      createdAt: DateTime.now(),
      steps: steps.map((step) => step.copyWith(
        status: WorkflowStep.statusPending,
        assignedAt: null,
        completedAt: null,
      )).toList(),
      data: newData ?? data,
      isTemplate: false,
      isActive: true,
    );
  }

  // Durum kontrolü
  bool get isDraft => status == statusDraft;
  bool get isCompleted => status == statusCompleted;
  bool get isCancelled => status == statusCancelled;
  
  // Adım kontrolü
  bool get hasActiveStep => steps.any((step) => step.status == WorkflowStep.statusActive);
  bool get allStepsCompleted => steps.every((step) => step.isCompleted);
  
  WorkflowStep? get currentStep {
    return steps.firstWhere(
      (step) => step.status == WorkflowStep.statusActive,
      orElse: () => steps.firstWhere(
        (step) => step.status == WorkflowStep.statusPending,
        orElse: () => steps.last,
      ),
    );
  }

  // İş akışı tipi kontrolleri
  bool get isApprovalWorkflow => type == typeApproval;
  bool get isTaskWorkflow => type == typeTask;
  bool get isDocumentWorkflow => type == typeDocument;
  bool get isRequestWorkflow => type == typeRequest;

  // Yeni yardımcı metodlar
  bool get isOverdue => 
      deadline != null && DateTime.now().isAfter(deadline!) && !isCompleted;

  bool get isOnHold => status == statusOnHold;

  String get priorityText {
    switch (priority) {
      case priorityUrgent:
        return 'Acil';
      case priorityHigh:
        return 'Yüksek';
      case priorityNormal:
        return 'Normal';
      case priorityLow:
        return 'Düşük';
      default:
        return 'Normal';
    }
  }

  Duration? get remainingTime {
    if (deadline == null || isCompleted) return null;
    return deadline!.difference(DateTime.now());
  }

  String get remainingTimeText {
    final remaining = remainingTime;
    if (remaining == null) return '';
    if (remaining.isNegative) return 'Gecikmiş';
    
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) return '$days gün';
    if (hours > 0) return '$hours saat';
    return '$minutes dakika';
  }

  bool canEdit(String userId) {
    return !isCompleted && !isCancelled && (createdBy == userId || 
        steps.any((step) => step.assignedTo == userId && step.isActive));
  }

  bool canDelete(String userId) {
    return createdBy == userId && !isCompleted && !isCancelled;
  }

  bool canAddComment(String userId) {
    return isActive && (createdBy == userId || 
        steps.any((step) => step.assignedTo == userId));
  }

  bool canAddFile(String userId) {
    return isActive && (createdBy == userId || 
        steps.any((step) => step.assignedTo == userId));
  }
}

class WorkflowHistory {
  final String id;
  final String action;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  WorkflowHistory({
    required this.id,
    required this.action,
    required this.userId,
    required this.timestamp,
    this.data = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
    };
  }

  factory WorkflowHistory.fromMap(Map<String, dynamic> map) {
    return WorkflowHistory(
      id: map['id'] as String,
      action: map['action'] as String,
      userId: map['userId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      data: Map<String, dynamic>.from(map['data'] as Map),
    );
  }
}

class WorkflowComment {
  final String id;
  final String text;
  final String userId;
  final DateTime timestamp;
  final List<String> attachments;

  WorkflowComment({
    required this.id,
    required this.text,
    required this.userId,
    required this.timestamp,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachments': attachments,
    };
  }

  factory WorkflowComment.fromMap(Map<String, dynamic> map) {
    return WorkflowComment(
      id: map['id'] as String,
      text: map['text'] as String,
      userId: map['userId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }
}

class WorkflowFile {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;
  final String uploadedBy;
  final DateTime uploadedAt;

  WorkflowFile({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory WorkflowFile.fromMap(Map<String, dynamic> map) {
    return WorkflowFile(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      size: map['size'] as int,
      uploadedBy: map['uploadedBy'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }
}

class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final String type;
  final String status;
  final String assignedTo;
  final bool isActive;
  final Map<String, dynamic>? conditions;
  final List<String>? trueSteps;
  final List<String>? falseSteps;
  final List<WorkflowStep>? parallelSteps;
  final Map<String, dynamic>? loopCondition;
  final List<WorkflowStep>? loopSteps;
  final Map<String, dynamic>? evaluationData;
  final bool? evaluationResult;

  WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.assignedTo,
    this.isActive = true,
    this.conditions,
    this.trueSteps,
    this.falseSteps,
    this.parallelSteps,
    this.loopCondition,
    this.loopSteps,
    this.evaluationData,
    this.evaluationResult,
  });

  // Adım tipleri
  static const String typeApproval = 'approval';
  static const String typeTask = 'task';
  static const String typeNotification = 'notification';
  static const String typeCondition = 'condition';
  static const String typeParallel = 'parallel';
  static const String typeLoop = 'loop';

  // Adım durumları
  static const String statusPending = 'pending';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusRejected = 'rejected';
  static const String statusSkipped = 'skipped';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'assignedTo': assignedTo,
      'isActive': isActive,
      if (conditions != null) 'conditions': conditions,
      if (trueSteps != null) 'trueSteps': trueSteps,
      if (falseSteps != null) 'falseSteps': falseSteps,
      if (parallelSteps != null)
        'parallelSteps': parallelSteps!.map((step) => step.toMap()).toList(),
      if (loopCondition != null) 'loopCondition': loopCondition,
      if (loopSteps != null)
        'loopSteps': loopSteps!.map((step) => step.toMap()).toList(),
      if (evaluationData != null) 'evaluationData': evaluationData,
      if (evaluationResult != null) 'evaluationResult': evaluationResult,
    };
  }

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      assignedTo: map['assignedTo'] as String,
      isActive: map['isActive'] as bool? ?? true,
      conditions: map['conditions'] as Map<String, dynamic>?,
      trueSteps: (map['trueSteps'] as List<dynamic>?)?.cast<String>(),
      falseSteps: (map['falseSteps'] as List<dynamic>?)?.cast<String>(),
      parallelSteps: (map['parallelSteps'] as List<dynamic>?)
          ?.map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      loopCondition: map['loopCondition'] as Map<String, dynamic>?,
      loopSteps: (map['loopSteps'] as List<dynamic>?)
          ?.map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      evaluationData: map['evaluationData'] as Map<String, dynamic>?,
      evaluationResult: map['evaluationResult'] as bool?,
    );
  }

  WorkflowStep copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? status,
    String? assignedTo,
    bool? isActive,
    Map<String, dynamic>? conditions,
    List<String>? trueSteps,
    List<String>? falseSteps,
    List<WorkflowStep>? parallelSteps,
    Map<String, dynamic>? loopCondition,
    List<WorkflowStep>? loopSteps,
    Map<String, dynamic>? evaluationData,
    bool? evaluationResult,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      isActive: isActive ?? this.isActive,
      conditions: conditions ?? this.conditions,
      trueSteps: trueSteps ?? this.trueSteps,
      falseSteps: falseSteps ?? this.falseSteps,
      parallelSteps: parallelSteps ?? this.parallelSteps,
      loopCondition: loopCondition ?? this.loopCondition,
      loopSteps: loopSteps ?? this.loopSteps,
      evaluationData: evaluationData ?? this.evaluationData,
      evaluationResult: evaluationResult ?? this.evaluationResult,
    );
  }

  bool get isConditionStep => type == typeCondition;
  bool get isParallelStep => type == typeParallel;
  bool get isLoopStep => type == typeLoop;
  bool get isCompleted => status == statusCompleted;
  bool get isRejected => status == statusRejected;
  bool get isSkipped => status == statusSkipped;
  bool get isPending => status == statusPending;
  bool get isActive => status == statusActive;

  List<WorkflowStep> get nextSteps {
    if (isConditionStep && evaluationResult != null) {
      return evaluationResult! ? trueSteps! : falseSteps!;
    }
    if (isParallelStep) {
      return parallelSteps ?? [];
    }
    if (isLoopStep) {
      return loopSteps ?? [];
    }
    return [];
  }
} 