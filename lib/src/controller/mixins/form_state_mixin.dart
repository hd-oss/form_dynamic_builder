import 'package:flutter/material.dart';

import '../../models/file_data.dart';
import '../../models/form_component.dart';
import '../../models/form_config.dart';
import '../../utils/form_constants.dart';

mixin FormStateMixin on ChangeNotifier {
  // Expected Members from FormController
  FormConfig get config;
  Map<String, String> get errors;

  final Map<String, dynamic> _values = {};
  Map<String, dynamic> get values => _values;

  /// Stores display text (labels) for components that have id/value pairs (e.g. select from API).
  final Map<String, String> _displayTexts = {};
  Map<String, String> get displayTexts => _displayTexts;

  void initializeValues() {
    _values.clear();
    _displayTexts.clear();
    final allComponents = getAllComponents();

    for (var component in allComponents) {
      if (component.type == FormConstants.typeButton) continue;
      if (component.defaultValue != null) {
        _values[component.key] = component.defaultValue;
      }
    }
  }

  List<FormComponent> getAllComponents() {
    final allComponents = [...config.components];
    for (var step in config.steps) {
      allComponents.addAll(step.components);
    }
    return allComponents;
  }

  dynamic getValue(String key) {
    return _values[key];
  }

  void updateValue(String key, dynamic value) {
    final component = findComponent(key);
    var processedValue = value;

    if (component != null && value is String) {
      if (component.type == FormConstants.typeNumber ||
          component.type == FormConstants.typeCurrency) {
        processedValue = num.tryParse(value) ?? value;
      } else if (component.textTransform == FormConstants.transformUppercase) {
        processedValue = value.toUpperCase();
      } else if (component.textTransform == FormConstants.transformLowercase) {
        processedValue = value.toLowerCase();
      }
    }

    _values[key] = processedValue;
    _displayTexts.remove(
        key); // clear stale display text when value updated without label
    // Clear error when user types
    if (errors.containsKey(key)) {
      errors.remove(key);
    }
    notifyListeners();
  }

  /// Updates a value along with its human-readable display text.
  /// Used by select/radio/tags widgets that have id+label pairs.
  void updateValueWithLabel(String key, dynamic value, String displayText) {
    updateValue(key, value);
    _displayTexts[key] = displayText;
  }

  /// Loads previously saved draft data into the form state.
  /// Expects the draftData to be the parsed JSON object produced by `resultMap`.
  void loadDraft(Map<String, dynamic> draftData) {
    draftData.forEach((key, value) {
      final component = findComponent(key);
      if (component == null) return;

      if (value is Map<String, dynamic> && value.containsKey('answerValue')) {
        // Value is a FormResultModel-like JSON structure
        var answerVal = value['answerValue'];
        final answerText = value['answerText'];

        // Hydrate FileData for upload components
        if (component.type == FormConstants.typeFile ||
            component.type == FormConstants.typeCamera ||
            component.type == FormConstants.typeSignature) {
          if (answerVal is List) {
            answerVal = answerVal
                .whereType<Map<String, dynamic>>()
                .map((e) => FileData.fromJson(e))
                .toList();
          } else if (answerVal is Map<String, dynamic>) {
            answerVal = FileData.fromJson(answerVal);
          }
        }

        if (answerText != null && answerText.toString().isNotEmpty) {
          updateValueWithLabel(key, answerVal, answerText.toString());
        } else {
          updateValue(key, answerVal);
        }
      } else {
        // Fallback for primitive/flat map injection
        updateValue(key, value);
      }
    });
  }

  FormComponent? findComponent(String key) {
    for (var component in getAllComponents()) {
      if (component.key == key) return component;
    }
    return null;
  }
}
