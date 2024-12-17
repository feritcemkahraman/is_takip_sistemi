import 'package:meta/meta.dart';
import 'validation_strategy.dart';

/// Validation rule interface
abstract class ValidationRule<T> {
  String get message;
  bool validate(T value);
}

/// Required field validation
class Required implements ValidationRule<dynamic> {
  @override
  final String message;

  const Required([this.message = 'Bu alan zorunludur']);

  @override
  bool validate(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

/// String length validation
class StringLength implements ValidationRule<String> {
  final int min;
  final int max;
  @override
  final String message;

  const StringLength({
    this.min = 0,
    this.max = 2147483647, 
    String? message,
  }) : message = message ?? 'Uzunluk $min ile $max arasında olmalıdır';

  @override
  bool validate(String value) {
    return value.length >= min && value.length <= max;
  }
}

/// List length validation
class ListLength implements ValidationRule<List> {
  final int min;
  final int max;
  @override
  final String message;

  const ListLength({
    this.min = 0,
    this.max = 2147483647, 
    String? message,
  }) : message = message ?? 'Liste uzunluğu $min ile $max arasında olmalıdır';

  @override
  bool validate(List value) {
    return value.length >= min && value.length <= max;
  }
}

/// Pattern validation
class Pattern implements ValidationRule<String> {
  final RegExp regex;
  @override
  final String message;

  const Pattern(this.regex, [this.message = 'Geçersiz format']);

  @override
  bool validate(String value) {
    return regex.hasMatch(value);
  }
}

/// Custom validation
class Custom<T> implements ValidationRule<T> {
  final bool Function(T value) validateFn;
  @override
  final String message;

  const Custom(this.validateFn, this.message);

  @override
  bool validate(T value) {
    return validateFn(value);
  }
}

/// Field validator
class FieldValidator<T> {
  final String fieldName;
  final List<ValidationRule<T>> rules;

  const FieldValidator(this.fieldName, this.rules);

  ValidationResult validate(T value) {
    final errors = <String>[];

    for (final rule in rules) {
      if (!rule.validate(value)) {
        errors.add('$fieldName: ${rule.message}');
      }
    }

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}

/// Model validator mixin
mixin ModelValidator {
  Map<String, List<ValidationRule>> get validationRules;

  ValidationResult validate() {
    final errors = <String>[];

    validationRules.forEach((field, rules) {
      final validator = FieldValidator(field, rules);
      final value = getField(field);
      final result = validator.validate(value);
      if (!result.isValid) {
        errors.addAll(result.errors);
      }
    });

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  dynamic getField(String fieldName);
}
