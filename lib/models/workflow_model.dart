import 'package:cloud_firestore/cloud_firestore.dart';

class WorkflowModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // draft, active, completed, cancelled
  final List<WorkflowStep> steps;
  final List<WorkflowCondition> conditions;
  final List<ParallelWorkflow> parallelFlows;
  final Map<String, dynamic> data;

  WorkflowModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.steps,
    this.conditions = const [],
    this.parallelFlows = const [],
    this.data = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
      'steps': steps.map((step) => step.toMap()).toList(),
      'conditions': conditions.map((condition) => condition.toMap()).toList(),
      'parallelFlows': parallelFlows.map((flow) => flow.toMap()).toList(),
      'data': data,
    };
  }

  factory WorkflowModel.fromMap(Map<String, dynamic> map) {
    return WorkflowModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      status: map['status'] as String,
      steps: (map['steps'] as List<dynamic>)
          .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      conditions: (map['conditions'] as List<dynamic>?)
              ?.map((condition) =>
                  WorkflowCondition.fromMap(condition as Map<String, dynamic>))
              .toList() ??
          [],
      parallelFlows: (map['parallelFlows'] as List<dynamic>?)
              ?.map((flow) =>
                  ParallelWorkflow.fromMap(flow as Map<String, dynamic>))
              .toList() ??
          [],
      data: map['data'] as Map<String, dynamic>? ?? {},
    );
  }

  // İş akışı durumları
  static const String statusDraft = 'draft';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Koşulları değerlendir
  bool evaluateConditions(Map<String, dynamic> context) {
    if (conditions.isEmpty) return true;

    for (final condition in conditions) {
      if (!condition.evaluate(context)) {
        return false;
      }
    }
    return true;
  }

  // Paralel akışları çalıştır
  Future<void> executeParallelFlows(Map<String, dynamic> context) async {
    if (parallelFlows.isEmpty) return;

    final futures = parallelFlows.map((flow) => flow.execute(context));
    await Future.wait(futures);
  }
}

class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final String type;
  final String assignedTo;
  final DateTime? dueDate;
  final String status;
  final List<WorkflowCondition> conditions;
  final Map<String, dynamic> data;
  final List<String> dependencies; // Bağımlı olduğu adımlar
  final int priority; // Öncelik seviyesi (1-5)
  final Duration? estimatedDuration; // Tahmini süre
  final DateTime? startDate; // Başlangıç tarihi
  final DateTime? endDate; // Bitiş tarihi
  final List<String> tags; // Etiketler
  final bool isOptional; // Opsiyonel adım mı?
  final bool isBlocking; // Diğer adımları blokluyor mu?

  WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.assignedTo,
    this.dueDate,
    required this.status,
    this.conditions = const [],
    this.data = const {},
    this.dependencies = const [],
    this.priority = 3,
    this.estimatedDuration,
    this.startDate,
    this.endDate,
    this.tags = const [],
    this.isOptional = false,
    this.isBlocking = true,
  });

  // Öncelik seviyeleri
  static const int priorityLowest = 1;
  static const int priorityLow = 2;
  static const int priorityNormal = 3;
  static const int priorityHigh = 4;
  static const int priorityHighest = 5;

  // Adım türleri
  static const String typeTask = 'task';
  static const String typeApproval = 'approval';
  static const String typeNotification = 'notification';
  static const String typeDecision = 'decision';
  static const String typeReview = 'review';
  static const String typeValidation = 'validation';

  // Adım durumları
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusBlocked = 'blocked';
  static const String statusSkipped = 'skipped';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'conditions': conditions.map((condition) => condition.toMap()).toList(),
      'data': data,
      'dependencies': dependencies,
      'priority': priority,
      'estimatedDuration': estimatedDuration?.inMinutes,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'tags': tags,
      'isOptional': isOptional,
      'isBlocking': isBlocking,
    };
  }

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      assignedTo: map['assignedTo'] as String,
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      status: map['status'] as String,
      conditions: (map['conditions'] as List<dynamic>?)
              ?.map((condition) =>
                  WorkflowCondition.fromMap(condition as Map<String, dynamic>))
              .toList() ??
          [],
      data: map['data'] as Map<String, dynamic>? ?? {},
      dependencies: (map['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      priority: map['priority'] as int? ?? 3,
      estimatedDuration: map['estimatedDuration'] != null
          ? Duration(minutes: map['estimatedDuration'] as int)
          : null,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isOptional: map['isOptional'] as bool? ?? false,
      isBlocking: map['isBlocking'] as bool? ?? true,
    );
  }

  // Adımın tamamlanma yüzdesi
  double get completionPercentage {
    if (status == statusCompleted) return 100;
    if (status == statusPending) return 0;
    if (status == statusCancelled) return 0;
    if (status == statusSkipped) return 100;

    // In progress durumu için süreye göre hesapla
    if (startDate != null && estimatedDuration != null) {
      final elapsed = DateTime.now().difference(startDate!);
      return (elapsed.inMinutes / estimatedDuration!.inMinutes * 100)
          .clamp(0, 100);
    }

    return 50; // Varsayılan olarak %50
  }

  // Gecikme durumu
  bool get isOverdue {
    if (status == statusCompleted || status == statusCancelled) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Kritik yol üzerinde mi?
  bool get isOnCriticalPath {
    return isBlocking && !isOptional && priority >= priorityHigh;
  }

  // Başlatılabilir mi?
  bool get canStart {
    return status == statusPending && !isBlocked;
  }

  // Bloke durumda mı?
  bool get isBlocked {
    return status == statusBlocked || dependencies.isNotEmpty;
  }

  WorkflowStep copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? assignedTo,
    DateTime? dueDate,
    String? status,
    List<WorkflowCondition>? conditions,
    Map<String, dynamic>? data,
    List<String>? dependencies,
    int? priority,
    Duration? estimatedDuration,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    bool? isOptional,
    bool? isBlocking,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      conditions: conditions ?? this.conditions,
      data: data ?? this.data,
      dependencies: dependencies ?? this.dependencies,
      priority: priority ?? this.priority,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      isOptional: isOptional ?? this.isOptional,
      isBlocking: isBlocking ?? this.isBlocking,
    );
  }
}

class WorkflowCondition {
  final String field;
  final String operator;
  final dynamic value;
  final String action; // continue, stop, skip

  WorkflowCondition({
    required this.field,
    required this.operator,
    required this.value,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operator': operator,
      'value': value,
      'action': action,
    };
  }

  factory WorkflowCondition.fromMap(Map<String, dynamic> map) {
    return WorkflowCondition(
      field: map['field'] as String,
      operator: map['operator'] as String,
      value: map['value'],
      action: map['action'] as String,
    );
  }

  // Operatörler
  static const String operatorEquals = 'equals';
  static const String operatorNotEquals = 'not_equals';
  static const String operatorGreaterThan = 'greater_than';
  static const String operatorLessThan = 'less_than';
  static const String operatorContains = 'contains';
  static const String operatorNotContains = 'not_contains';

  // Aksiyonlar
  static const String actionContinue = 'continue';
  static const String actionStop = 'stop';
  static const String actionSkip = 'skip';

  // Koşulu değerlendir
  bool evaluate(Map<String, dynamic> context) {
    final fieldValue = _getFieldValue(field, context);
    
    switch (operator) {
      case operatorEquals:
        return fieldValue == value;
      case operatorNotEquals:
        return fieldValue != value;
      case operatorGreaterThan:
        return (fieldValue as num) > (value as num);
      case operatorLessThan:
        return (fieldValue as num) < (value as num);
      case operatorContains:
        return (fieldValue as String).contains(value as String);
      case operatorNotContains:
        return !(fieldValue as String).contains(value as String);
      default:
        return false;
    }
  }

  dynamic _getFieldValue(String field, Map<String, dynamic> context) {
    final parts = field.split('.');
    dynamic value = context;
    
    for (final part in parts) {
      if (value is Map) {
        value = value[part];
      } else {
        return null;
      }
    }
    
    return value;
  }
}

class ParallelWorkflow {
  final String id;
  final String title;
  final List<WorkflowStep> steps;
  final bool waitForAll;
  final Duration timeout;
  final String status; // pending, in_progress, completed, cancelled

  ParallelWorkflow({
    required this.id,
    required this.title,
    required this.steps,
    required this.waitForAll,
    required this.timeout,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
      'waitForAll': waitForAll,
      'timeout': timeout.inSeconds,
      'status': status,
    };
  }

  factory ParallelWorkflow.fromMap(Map<String, dynamic> map) {
    return ParallelWorkflow(
      id: map['id'] as String,
      title: map['title'] as String,
      steps: (map['steps'] as List<dynamic>)
          .map((step) => WorkflowStep.fromMap(step as Map<String, dynamic>))
          .toList(),
      waitForAll: map['waitForAll'] as bool,
      timeout: Duration(seconds: map['timeout'] as int),
      status: map['status'] as String,
    );
  }

  // Paralel akış durumları
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Paralel akışı çalıştır
  Future<void> execute(Map<String, dynamic> context) async {
    final futures = steps.map((step) async {
      if (step.evaluateConditions(context)) {
        // Adımı çalıştır
        // TODO: Adım çalıştırma mantığı eklenecek
      }
    });

    if (waitForAll) {
      await Future.wait(futures).timeout(timeout);
    } else {
      await Future.any(futures).timeout(timeout);
    }
  }
} 