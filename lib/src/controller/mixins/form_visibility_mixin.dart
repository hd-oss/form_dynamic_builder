import '../../models/form_config.dart';
import '../../models/form_component.dart';
import '../../models/conditional_config.dart';
import '../../models/file_data.dart';
import '../../utils/form_constants.dart';

mixin FormVisibilityMixin {
  // Expected Members
  FormConfig get config;
  Map<String, dynamic> get values;
  FormComponent? findComponent(String key);

  /// Returns only values for components that are currently visible.
  /// Values are processed to "submission format" (e.g. unwrapping FileData).
  Map<String, dynamic> get visibleValues {
    final allComponents = getAllComponents();

    final visibleKeys = allComponents
        .where(
            (c) => c.type != FormConstants.typeButton && isComponentVisible(c))
        .map((c) => c.key)
        .toSet();

    final result = <String, dynamic>{};
    for (var key in visibleKeys) {
      if (values.containsKey(key)) {
        result[key] = _unwrapValue(values[key]);
      }
    }
    return result;
  }

  /// Returns all form values, including hidden ones.
  /// Values are processed to "submission format" (unwrapping FileData).
  Map<String, dynamic> get allValues {
    final result = <String, dynamic>{};
    for (var entry in values.entries) {
      result[entry.key] = _unwrapValue(entry.value);
    }
    return result;
  }

  /// Helper to convert internal representation (like FileData) to submission format.
  dynamic _unwrapValue(dynamic value) {
    if (value is FileData) {
      return value.submissionValue;
    }
    if (value is List) {
      return value.map((e) => e is FileData ? e.submissionValue : e).toList();
    }
    return value;
  }

  /// Gets all components across all steps and top-level.
  List<FormComponent> getAllComponents() {
    final allComponents = [...config.components];
    for (var step in config.steps) {
      allComponents.addAll(step.components);
    }
    return allComponents;
  }

  bool isComponentVisible(FormComponent component) {
    return _isComponentVisible(component, {});
  }

  bool _isComponentVisible(FormComponent component, Set<String> visited) {
    if (visited.contains(component.key)) return true;
    visited.add(component.key);

    if (component.hidden) return false;
    final cond = component.conditional;
    if (cond == null || cond.conditions.isEmpty) return true;

    bool result = _evaluateCondition(cond.conditions.first, visited);

    for (var i = 1; i < cond.conditions.length; i++) {
      final condition = cond.conditions[i];
      final condResult = _evaluateCondition(condition, visited);

      if (condition.logicWithPrevious == FormConstants.logicOr) {
        result = result || condResult;
      } else {
        result = result && condResult;
      }
    }

    return cond.show ? result : !result;
  }

  bool _evaluateCondition(Condition condition, Set<String> visited) {
    final dependencyComponent = findComponent(condition.when);
    bool dependencyVisible = true;
    if (dependencyComponent != null) {
      dependencyVisible =
          _isComponentVisible(dependencyComponent, Set.from(visited));
    }

    final fieldValue = dependencyVisible ? values[condition.when] : null;

    switch (condition.operator) {
      case FormConstants.opEquals:
        if (fieldValue is List) {
          return fieldValue.contains(condition.value);
        }
        return fieldValue == condition.value;
      case FormConstants.opNotEquals:
        if (fieldValue is List) {
          return !fieldValue.contains(condition.value);
        }
        return fieldValue != condition.value;
      case FormConstants.opGreaterThan:
        return _compare(fieldValue, condition.value) > 0;
      case FormConstants.opGreaterOrEqual:
        return _compare(fieldValue, condition.value) >= 0;
      case FormConstants.opLessThan:
        return _compare(fieldValue, condition.value) < 0;
      case FormConstants.opLessOrEqual:
        return _compare(fieldValue, condition.value) <= 0;
      case FormConstants.opContains:
        return _contains(fieldValue, condition.value);
      case FormConstants.opNotContains:
        return !_contains(fieldValue, condition.value);
      case FormConstants.opNotEmpty:
        if (fieldValue == null) return false;
        if (fieldValue is String) return fieldValue.isNotEmpty;
        if (fieldValue is List) return fieldValue.isNotEmpty;
        return true;
      case FormConstants.opIsEmpty:
        if (fieldValue == null) return true;
        if (fieldValue is String) return fieldValue.isEmpty;
        if (fieldValue is List) return fieldValue.isEmpty;
        return false;
      default:
        return true;
    }
  }

  int _compare(dynamic a, dynamic b) {
    if (a == null || b == null) return 0;
    if (a is num && b is num) return a.compareTo(b);

    final numA = a is String ? num.tryParse(a) : (a is num ? a : null);
    final numB = b is String ? num.tryParse(b) : (b is num ? b : null);
    if (numA != null && numB != null) return numA.compareTo(numB);

    return a.toString().compareTo(b.toString());
  }

  bool _contains(dynamic a, dynamic b) {
    if (a == null) return false;
    if (b == null) return false;

    if (a is List) {
      return a.contains(b);
    }
    return a.toString().contains(b.toString());
  }
}
