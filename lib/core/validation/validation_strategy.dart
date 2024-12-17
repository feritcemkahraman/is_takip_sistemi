import 'package:is_takip_sistemi/models/workflow_model.dart';

/// Temel validasyon strateji arayüzü
abstract class ValidationStrategy {
  ValidationResult validate(dynamic entity);
  String get validationName;
}

/// İş akışı durum validasyon stratejisi
class WorkflowStatusValidationStrategy implements ValidationStrategy {
  @override
  String get validationName => 'Workflow Status Validation';

  @override
  ValidationResult validate(dynamic entity) {
    if (entity is! WorkflowModel) {
      return ValidationResult.failure(['Invalid entity type for workflow status validation']);
    }

    final errors = <String>[];
    final workflow = entity;
    
    // Tüm adımlar tamamlanmadan iş akışı tamamlanamaz
    if (workflow.status == WorkflowModel.statusCompleted && 
        !workflow.steps.every((s) => s.status == WorkflowStep.statusCompleted)) {
      errors.add('Tüm adımlar tamamlanmadan iş akışı tamamlanamaz');
    }

    // Başlanmamış iş akışında aktif adım olamaz
    if (workflow.status == WorkflowModel.statusNotStarted && 
        workflow.steps.any((s) => s.status != WorkflowStep.statusNotStarted)) {
      errors.add('Başlanmamış iş akışında aktif veya tamamlanmış adım olamaz');
    }

    return errors.isEmpty 
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

/// Bağımlılık validasyon stratejisi
class DependencyValidationStrategy implements ValidationStrategy {
  @override
  String get validationName => 'Dependency Validation';

  @override
  ValidationResult validate(dynamic entity) {
    if (entity is! WorkflowModel) {
      return ValidationResult.failure(['Invalid entity type for dependency validation']);
    }

    final errors = <String>[];
    final workflow = entity;
    
    for (final step in workflow.steps) {
      if (step.dependencies.isEmpty) continue;

      // Bağımlı adımların varlık kontrolü
      final missingDeps = step.dependencies
          .where((depId) => !workflow.steps.any((s) => s.id == depId))
          .toList();
      
      if (missingDeps.isNotEmpty) {
        errors.add('Bulunamayan bağımlı adımlar: ${missingDeps.join(", ")}');
        continue;
      }

      // Bağımlılık durum kontrolü
      final dependentSteps = workflow.steps
          .where((s) => step.dependencies.contains(s.id));
      
      for (final depStep in dependentSteps) {
        if (step.status == WorkflowStep.statusCompleted && 
            depStep.status != WorkflowStep.statusCompleted) {
          errors.add('${step.title} adımı, bağımlı ${depStep.title} adımı tamamlanmadan bitirilemez');
        }

        if (step.status == WorkflowStep.statusInProgress && 
            depStep.status == WorkflowStep.statusNotStarted) {
          errors.add('${step.title} adımı, bağımlı ${depStep.title} adımı başlamadan başlatılamaz');
        }
      }
    }

    return errors.isEmpty 
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

/// Validasyon yöneticisi
class ValidationManager {
  final List<ValidationStrategy> _strategies;

  ValidationManager([List<ValidationStrategy>? strategies])
      : _strategies = strategies ?? [];

  void addStrategy(ValidationStrategy strategy) {
    _strategies.add(strategy);
  }

  ValidationResult validateAll(dynamic entity) {
    final allErrors = <String>[];
    
    for (final strategy in _strategies) {
      final result = strategy.validate(entity);
      if (!result.isValid) {
        allErrors.addAll(result.errors);
      }
    }

    return allErrors.isEmpty 
        ? ValidationResult.success()
        : ValidationResult.failure(allErrors);
  }
}
