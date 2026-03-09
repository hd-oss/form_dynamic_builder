import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/form_config.dart';
import '../../models/form_component.dart';
import '../../models/components/all_components.dart';
import '../../models/conditional_config.dart';
import '../../models/file_data.dart';
import '../../models/form_result.dart';
import '../../utils/form_constants.dart';

mixin FormVisibilityMixin {
  // ── Expected Members ──────────────────────────────────────────────────

  FormConfig get config;
  Map<String, dynamic> get values;
  Map<String, String> get displayTexts;
  FormComponent? findComponent(String key);

  // ── API Cache ─────────────────────────────────────────────────────────

  /// Cache for resolved API values used in conditions.
  /// Key: "$method::$url::$valuePath", Value: resolved dynamic value.
  final Map<String, dynamic> _conditionApiCache = {};

  // ── Submission Values ─────────────────────────────────────────────────

  /// Returns the form state in the expected submission format:
  /// ```json
  /// {
  ///   "fieldKey": {
  ///     "answerText": "Label / human-readable value",
  ///     "answerValue": <raw stored value>,
  ///     "resultMapper": {          // only present when destinationTable/Column are set
  ///       "destinationTbl": "...",
  ///       "destinationColl": "..."
  ///     }
  ///   }
  /// }
  /// ```
  Map<String, FormResultModel> get resultMap {
    final allComponents = getAllComponents();

    final visibleComponents = allComponents
        .where(
            (c) => c.type != FormConstants.typeButton && isComponentVisible(c))
        .toList();

    final result = <String, FormResultModel>{};
    for (final component in visibleComponents) {
      if (!values.containsKey(component.key)) continue;

      final rawValue = values[component.key];
      final answerValue = _unwrapValue(rawValue);
      final answerText =
          _resolveAnswerText(component, rawValue, answerValue, component.key);

      if (component.type != FormConstants.typeFile &&
          component.type != FormConstants.typeCamera &&
          component.type != FormConstants.typeSignature) {
        result[component.key] = FormResultModel(
            answerText: answerText,
            answerValue: answerValue,
            resultMapper: ResultMapper(
                destinationTbl: component.destinationTable ?? '',
                destinationColl: component.destinationColumn ?? ''));
      } else {
        final List<dynamic> answerFile = [];

        if (rawValue is List) {
          answerFile.addAll(
            rawValue.map((e) => e is FileData ? e.uploadResponse : e),
          );
        } else if (rawValue is FileData) {
          answerFile.add(rawValue.uploadResponse);
        } else if (rawValue != null) {
          answerFile.add(rawValue);
        }

        result[component.key] = FormResultModel(
          answerText: '',
          answerValue: '',
          answerFile: answerFile.isEmpty ? null : answerFile,
          resultMapper: ResultMapper(
            destinationTbl: component.destinationTable ?? '',
            destinationColl: component.destinationColumn ?? '',
          ),
        );
      }
    }
    return result;
  }

  /// Returns true if the component has a static options list (select, radio, etc.).
  bool _componentHasOptions(FormComponent component) {
    final json = component.toJson();
    final options = json['options'];
    return options is List && options.isNotEmpty;
  }

  /// Resolves the human-readable label for the given [rawValue].
  /// - Priority 1: displayTexts map (set by widgets with dynamic API options).
  /// - Priority 2: static options label lookup.
  /// - For components without options (text, number): returns empty string.
  String _resolveAnswerText(
      FormComponent component, dynamic rawValue, dynamic answerValue,
      [String? componentKey]) {
    // Check if a display text was explicitly set (e.g. select from API)
    if (componentKey != null && displayTexts.containsKey(componentKey)) {
      return displayTexts[componentKey]!;
    }

    if (!_componentHasOptions(component)) return '';

    // For list-based answers (select-boxes, tags), accumulate labels
    if (rawValue is List) {
      final labels = rawValue
          .map((v) => _findOptionLabel(component, v) ?? v.toString())
          .toList();
      return labels.join(', ');
    }

    return _findOptionLabel(component, rawValue) ?? '';
  }

  /// Finds the option label matching [val] in the component's static options list.
  /// Returns null if the component has no static options or no match is found.
  String? _findOptionLabel(FormComponent component, dynamic val) {
    final json = component.toJson();
    final options = json['options'];
    if (options is! List || options.isEmpty) return null;

    for (final opt in options) {
      if (opt is Map) {
        final optValue = opt['value']?.toString();
        if (optValue == val?.toString()) {
          return opt['label']?.toString();
        }
      }
    }
    return null;
  }

  // ── API Cache Priming ─────────────────────────────────────────────────

  /// Fetches all unique API endpoints referenced in conditions and caches
  /// their resolved values. Call this once after loading form config,
  /// then again whenever conditional API data should be refreshed.
  Future<void> refreshConditionalApiValues() async {
    final onApiQuery = config.onApiQuery;
    if (onApiQuery == null) return;

    // Collect all unique ConditionalApiConfig instances
    final toFetch = <ConditionalApiConfig>{};
    for (final comp in getAllComponents()) {
      final cond = comp.conditional;
      if (cond == null) continue;
      for (final c in cond.conditions) {
        if (c.whenSource == FormConstants.whenSourceApi && c.whenApi != null) {
          toFetch.add(c.whenApi!);
        }
        if (c.valueSource == FormConstants.valueSourceApi &&
            c.valueApi != null) {
          toFetch.add(c.valueApi!);
        }
      }
    }

    // Fetch in parallel
    await Future.wait(toFetch.map((apiCfg) async {
      final cacheKey = '${apiCfg.method}::${apiCfg.url}::${apiCfg.valuePath}';
      if (_conditionApiCache.containsKey(cacheKey)) return;
      try {
        final raw = await onApiQuery(apiCfg.url, apiCfg.method, {}, '');
        _conditionApiCache[cacheKey] = _extractFromPath(raw, apiCfg.valuePath);
      } catch (e) {
        if (kDebugMode) print('Condition API fetch error [$cacheKey]: $e');
        _conditionApiCache[cacheKey] = null;
      }
    }));
  }

  // ── Visibility Evaluation ─────────────────────────────────────────────

  bool isComponentVisible(FormComponent component) {
    return _isComponentVisible(component, {});
  }

  bool _isComponentVisible(FormComponent component, Set<String> visited) {
    if (!_isComponentSelfVisible(component, visited)) return false;

    // Check if any parent panel is hidden. If so, this component is also hidden.
    final parent = _findParentPanelOf(component);
    if (parent != null && !_isComponentVisible(parent, visited)) {
      return false;
    }

    return true;
  }

  PanelComponent? _findParentPanelOf(FormComponent target) {
    PanelComponent? searchInList(
        List<FormComponent> list, PanelComponent? currentParent) {
      for (final comp in list) {
        if (comp.id == target.id || comp.key == target.key) {
          return currentParent;
        }
        if (comp is PanelComponent) {
          final found = searchInList(comp.components, comp);
          if (found != null) return found;
        }
      }
      return null;
    }

    final inRoot = searchInList(config.components, null);
    if (inRoot != null) return inRoot;

    for (final step in config.steps) {
      final inStep = searchInList(step.components, null);
      if (inStep != null) return inStep;
    }
    return null;
  }

  bool _isComponentSelfVisible(FormComponent component, Set<String> visited) {
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
    // 1. Resolve "when" (left side)
    final fieldValue = _resolveWhenValue(condition, visited);

    // 2. Resolve comparison value (right side)
    final comparisonValue = _resolveComparisonValue(condition, visited);

    // 3. Compare
    return _compare(fieldValue, condition.operator, comparisonValue);
  }

  // ── Value Resolution ──────────────────────────────────────────────────

  /// Resolves the left-hand ("when") value of a condition.
  dynamic _resolveWhenValue(Condition condition, Set<String> visited) {
    if (condition.whenSource == FormConstants.whenSourceApi) {
      // Get cached API result
      if (condition.whenApi == null) return null;
      final cfg = condition.whenApi!;
      final key = '${cfg.method}::${cfg.url}::${cfg.valuePath}';
      return _conditionApiCache[key];
    }

    // Default: field
    final dependencyComponent = findComponent(condition.when);
    if (dependencyComponent != null) {
      final visible =
          _isComponentVisible(dependencyComponent, Set.from(visited));
      if (!visible) return null;
    }
    return values[condition.when];
  }

  /// Resolves the right-hand (comparison) value of a condition.
  dynamic _resolveComparisonValue(Condition condition, Set<String> visited) {
    switch (condition.valueSource) {
      case FormConstants.valueSourceApi:
        if (condition.valueApi == null) return condition.value;
        final cfg = condition.valueApi!;
        final key = '${cfg.method}::${cfg.url}::${cfg.valuePath}';
        return _conditionApiCache[key];

      case FormConstants.valueSourceField:
        if (condition.valueFieldKey == null) return condition.value;
        final depComp = findComponent(condition.valueFieldKey!);
        if (depComp != null) {
          final visible = _isComponentVisible(depComp, Set.from(visited));
          if (!visible) return null;
        }
        return values[condition.valueFieldKey!];

      // "manual" or default
      default:
        return condition.value;
    }
  }

  // ── Comparison Engine ─────────────────────────────────────────────────

  bool _compare(dynamic fieldValue, String operator, dynamic comparisonValue) {
    switch (operator) {
      case FormConstants.opEquals:
        return _equals(fieldValue, comparisonValue);
      case FormConstants.opNotEquals:
        return !_equals(fieldValue, comparisonValue);
      case FormConstants.opGreaterThan:
        return _numCompare(fieldValue, comparisonValue) > 0;
      case FormConstants.opGreaterOrEqual:
        return _numCompare(fieldValue, comparisonValue) >= 0;
      case FormConstants.opLessThan:
        return _numCompare(fieldValue, comparisonValue) < 0;
      case FormConstants.opLessOrEqual:
        return _numCompare(fieldValue, comparisonValue) <= 0;
      case FormConstants.opContains:
        return _contains(fieldValue, comparisonValue);
      case FormConstants.opNotContains:
        return !_contains(fieldValue, comparisonValue);
      case FormConstants.opNotEmpty:
        if (fieldValue == null) return false;
        if (fieldValue is String) return fieldValue.trim().isNotEmpty;
        if (fieldValue is Iterable) {
          if (fieldValue.isEmpty) return false;
          // For multiple files, all must be successfully uploaded
          if (fieldValue.every((e) => e is FileData)) {
            return !fieldValue.any((e) => !(e as FileData).isUploaded);
          }
          return true;
        }
        if (fieldValue is FileData) return fieldValue.isUploaded;
        return true;
      case FormConstants.opIsEmpty:
        if (fieldValue == null) return true;
        if (fieldValue is String) return fieldValue.trim().isEmpty;
        if (fieldValue is Iterable) {
          if (fieldValue.isEmpty) return true;
          if (fieldValue.every((e) => e is FileData)) {
            return fieldValue.any((e) => !(e as FileData).isUploaded);
          }
          return false;
        }
        if (fieldValue is FileData) return !fieldValue.isUploaded;
        return false;
      default:
        return true;
    }
  }

  bool _equals(dynamic a, dynamic b) {
    if (a is List) return a.contains(b);
    // Normalize to string for cross-type comparison (e.g. int 1 == "1")
    final aStr = a?.toString();
    final bStr = b?.toString();
    return aStr == bStr;
  }

  int _numCompare(dynamic a, dynamic b) {
    if (a == null || b == null) return 0;
    if (a is num && b is num) return a.compareTo(b);
    final numA = a is String ? num.tryParse(a) : (a is num ? a : null);
    final numB = b is String ? num.tryParse(b) : (b is num ? b : null);
    if (numA != null && numB != null) return numA.compareTo(numB);
    return a.toString().compareTo(b.toString());
  }

  bool _contains(dynamic a, dynamic b) {
    if (a == null || b == null) return false;
    if (a is List) return a.contains(b);
    return a.toString().contains(b.toString());
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Gets all components across all pages/steps, including those nested in panels.
  List<FormComponent> getAllComponents() {
    final all = <FormComponent>[];

    void extractComponents(List<FormComponent> components) {
      for (final comp in components) {
        all.add(comp);
        if (comp is PanelComponent) {
          extractComponents(comp.components);
        }
      }
    }

    extractComponents(config.components);
    for (var step in config.steps) {
      extractComponents(step.components);
    }
    return all;
  }

  /// Resolves a dot-notated path from a decoded JSON response.
  dynamic _extractFromPath(dynamic raw, String path) {
    if (path.isEmpty) return raw;
    dynamic decoded = raw;
    // If raw is a String (JSON text), decode first
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {}
    }
    for (final segment in path.split('.')) {
      if (decoded is Map<String, dynamic>) {
        decoded = decoded[segment];
      } else if (decoded is List && int.tryParse(segment) != null) {
        decoded = decoded[int.parse(segment)];
      } else {
        return null;
      }
    }
    return decoded;
  }

  /// Unwraps FileData objects to their submission values.
  dynamic _unwrapValue(dynamic value) {
    if (value is FileData) return value.uploadResponse;
    if (value is List) {
      return value.map((e) => e is FileData ? e.uploadResponse : e).toList();
    }
    return value;
  }
}
