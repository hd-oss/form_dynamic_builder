import '../utils/form_constants.dart';

/// Configuration for a conditional API endpoint used in condition when/value sources.
class ConditionalApiConfig {
  /// API endpoint URL.
  final String url;

  /// HTTP method (GET, POST, etc.).
  final String method;

  /// Dot-notated path to extract from the response (e.g. "data.value" or "index").
  final String valuePath;

  const ConditionalApiConfig({
    this.url = '',
    this.method = 'GET',
    this.valuePath = '',
  });

  factory ConditionalApiConfig.fromJson(Map<String, dynamic> json) {
    return ConditionalApiConfig(
      url: json['url'] as String? ?? '',
      method: json['method'] as String? ?? 'GET',
      valuePath: json['valuePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'method': method,
        'valuePath': valuePath,
      };
}

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

/// A single condition that evaluates a field's or API's value.
class Condition {
  // ── WHEN side ──────────────────────────────────────────────────────────

  /// The key of the field to watch (used when [whenSource] == "field").
  final String when;

  /// Where to get the "when" value: `"field"` (default) or `"api"`.
  final String whenSource;

  /// API config for reading the "when" value (used when [whenSource] == "api").
  final ConditionalApiConfig? whenApi;

  // ── Comparison ─────────────────────────────────────────────────────────

  /// The comparison operator: "eq", "neq", "gt", "gte", "lt", "lte", "contains", etc.
  final String operator;

  // ── VALUE side ─────────────────────────────────────────────────────────

  /// Static comparison value (used when [valueSource] == "manual").
  final dynamic value;

  /// Where to get the comparison value: `"manual"` (default), `"api"`, or `"field"`.
  final String valueSource;

  /// API config for reading the comparison value (used when [valueSource] == "api").
  final ConditionalApiConfig? valueApi;

  /// Key of the form field whose current value is the comparison value
  /// (used when [valueSource] == "field").
  final String? valueFieldKey;

  // ── Chaining ───────────────────────────────────────────────────────────

  /// How to combine with the previous condition: "and" or "or".
  final String logicWithPrevious;

  Condition({
    this.when = '',
    this.whenSource = FormConstants.whenSourceField,
    this.whenApi,
    required this.operator,
    this.value,
    this.valueSource = FormConstants.valueSourceManual,
    this.valueApi,
    this.valueFieldKey,
    this.logicWithPrevious = FormConstants.logicAnd,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      when: json['when'] as String? ?? '',
      whenSource:
          json['whenSource'] as String? ?? FormConstants.whenSourceField,
      whenApi: json['whenApi'] != null
          ? ConditionalApiConfig.fromJson(
              json['whenApi'] as Map<String, dynamic>)
          : null,
      operator: json['operator'] as String? ?? FormConstants.opEquals,
      value: json['value'],
      valueSource:
          json['valueSource'] as String? ?? FormConstants.valueSourceManual,
      valueApi: json['valueApi'] != null
          ? ConditionalApiConfig.fromJson(
              json['valueApi'] as Map<String, dynamic>)
          : null,
      valueFieldKey: json['valueFieldKey'] as String?,
      logicWithPrevious:
          json['logicWithPrevious'] as String? ?? FormConstants.logicAnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'when': when,
      'whenSource': whenSource,
      if (whenApi != null) 'whenApi': whenApi!.toJson(),
      'operator': operator,
      if (value != null) 'value': value,
      'valueSource': valueSource,
      if (valueApi != null) 'valueApi': valueApi!.toJson(),
      if (valueFieldKey != null) 'valueFieldKey': valueFieldKey,
      'logicWithPrevious': logicWithPrevious,
    };
  }
}
