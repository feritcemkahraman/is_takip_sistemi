import 'package:meta/meta.dart';
import 'validator.dart';

/// Cross-field validation rule interface
abstract class CrossFieldValidationRule {
  String get message;
  bool validate(Map<String, dynamic> fields);
}

/// Dependency validation rule
class DependencyValidationRule implements CrossFieldValidationRule {
  @override
  final String message;

  const DependencyValidationRule([
    this.message = 'Bağımlılık zincirinde döngüsel referans bulundu',
  ]);

  @override
  bool validate(Map<String, dynamic> fields) {
    final steps = fields['steps'] as List<dynamic>;
    final Map<String, Set<String>> dependencies = {};
    
    // Bağımlılık grafiğini oluştur
    for (final step in steps) {
      final id = step.id as String;
      final deps = step.dependencies as List<String>? ?? [];
      dependencies[id] = deps.toSet();
    }

    // Döngüsel bağımlılık kontrolü
    return !_hasCycle(dependencies);
  }

  bool _hasCycle(Map<String, Set<String>> graph) {
    final Set<String> visited = {};
    final Set<String> recStack = {};

    bool _hasCycleUtil(String node) {
      if (recStack.contains(node)) return true;
      if (visited.contains(node)) return false;

      visited.add(node);
      recStack.add(node);

      for (final neighbor in graph[node] ?? {}) {
        if (_hasCycleUtil(neighbor)) return true;
      }

      recStack.remove(node);
      return false;
    }

    for (final node in graph.keys) {
      if (_hasCycleUtil(node)) return true;
    }

    return false;
  }
}

/// Assignment consistency validation rule
class AssignmentConsistencyRule implements CrossFieldValidationRule {
  @override
  final String message;

  const AssignmentConsistencyRule([
    this.message = 'Adımlara atanan kişiler iş akışına atanmış olmalıdır',
  ]);

  @override
  bool validate(Map<String, dynamic> fields) {
    final workflowAssignees = fields['assignedTo'] as List<String>;
    final steps = fields['steps'] as List<dynamic>;

    final stepAssignees = steps
        .expand((step) => step.assignedTo as List<String>)
        .toSet();

    return stepAssignees.every((user) => workflowAssignees.contains(user));
  }
}

/// Date consistency validation rule
class DateConsistencyRule implements CrossFieldValidationRule {
  @override
  final String message;

  const DateConsistencyRule([
    this.message = 'Adım tarihleri iş akışı zaman sınırları içinde olmalıdır',
  ]);

  @override
  bool validate(Map<String, dynamic> fields) {
    final steps = fields['steps'] as List<dynamic>;
    final now = DateTime.now();

    for (final step in steps) {
      final dueDate = step.dueDate as DateTime?;
      if (dueDate == null) continue;

      // Geçmiş tarihli adım olmamalı
      if (dueDate.isBefore(now)) return false;

      // Bağımlı adımların tarihleri kontrol edilmeli
      final dependencies = step.dependencies as List<String>? ?? [];
      if (dependencies.isEmpty) continue;

      for (final depId in dependencies) {
        final depStep = steps.cast<dynamic>().firstWhere(
          (s) => s.id == depId,
          orElse: () => _DummyStep(),
        );
        if (depStep is _DummyStep) continue;

        final depDueDate = depStep.dueDate as DateTime?;
        if (depDueDate == null) continue;

        // Bağımlı adımın bitiş tarihi, bağımlı olunan adımın bitiş tarihinden sonra olmalı
        if (dueDate.isBefore(depDueDate)) return false;
      }
    }

    return true;
  }
}

class _DummyStep {
  final String id = '';
  final DateTime? dueDate = null;
}

/// Cross-field validator mixin
mixin CrossFieldValidator {
  List<CrossFieldValidationRule> get crossFieldRules;

  ValidationResult validateCrossFields() {
    final errors = <String>[];
    final fields = getCrossFieldValues();

    for (final rule in crossFieldRules) {
      if (!rule.validate(fields)) {
        errors.add(rule.message);
      }
    }

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  Map<String, dynamic> getCrossFieldValues();
}
