import 'package:flutter/material.dart';

import '../../models/form_component.dart';
import '../../models/form_config.dart';
import '../../utils/form_constants.dart';

mixin FormStateMixin on ChangeNotifier {
  // Expected Members from FormController
  FormConfig get config;
  Map<String, String> get errors;

  final Map<String, dynamic> _values = {};
  Map<String, dynamic> get values => _values;

  void initializeValues() {
    _values.clear();
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
    // Clear error when user types
    if (errors.containsKey(key)) {
      errors.remove(key);
    }
    notifyListeners();
  }

  FormComponent? findComponent(String key) {
    // Search in top level components
    for (var component in config.components) {
      if (component.key == key) return component;
    }
    // Search in steps
    for (var step in config.steps) {
      for (var component in step.components) {
        if (component.key == key) return component;
      }
    }
    return null;
  }
}
