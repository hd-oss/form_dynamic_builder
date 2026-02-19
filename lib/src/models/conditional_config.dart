import '../utils/form_constants.dart';

/// Configuration for conditional visibility of a form component.
class ConditionalConfig {
  final bool show;
  final List<Condition> conditions;

  ConditionalConfig({
    required this.show,
    this.conditions = const [],
  });

  factory ConditionalConfig.fromJson(Map<String, dynamic> json) {
    return ConditionalConfig(
      show: json['show'] ?? true,
      conditions: (json['conditions'] as List?)
              ?.map((e) => Condition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show': show,
      'conditions': conditions.map((e) => e.toJson()).toList(),
    };
  }
}

/// A single condition that evaluates a field's value.
class Condition {
  /// The key of the field to watch.
  final String when;

  /// The comparison operator: "eq", "neq", "notEmpty", "isEmpty".
  final String operator;

  /// The value to compare against (for "eq" and "neq").
  final dynamic value;

  /// How to combine with the previous condition: "and" or "or".
  final String logicWithPrevious;

  Condition({
    required this.when,
    required this.operator,
    this.value,
    this.logicWithPrevious = FormConstants.logicAnd,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      when: json['when'] ?? '',
      operator: json['operator'] ?? FormConstants.opEquals,
      value: json['value'],
      logicWithPrevious: json['logicWithPrevious'] ?? FormConstants.logicAnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'when': when,
      'operator': operator,
      if (value != null) 'value': value,
      'logicWithPrevious': logicWithPrevious,
    };
  }
}
