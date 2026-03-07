import 'package:flutter/material.dart';

import '../../models/components/all_components.dart';
import '../../models/file_data.dart';
import '../../models/form_component.dart';
import '../../models/form_config.dart';
import '../../models/validation_rule.dart';
import '../../utils/form_constants.dart';

mixin FormValidationMixin on ChangeNotifier {
  // Expected Members
  FormConfig get config;
  Map<String, dynamic> get values;
  bool isComponentVisible(FormComponent component);

  // State managed by this mixin
  final Map<String, String> _errors = {};
  Map<String, String> get errors => _errors;

  final Map<String, FocusNode> _focusNodes = {};

  FocusNode getFocusNode(String key) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
    }
    return _focusNodes[key]!;
  }

  void disposeValidationResources() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  /// Disposes and clears all existing FocusNodes.
  /// Call this during form reset so stale nodes don't block input.
  void clearFocusNodes() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  bool validate() {
    _errors.clear();
    bool isValid = true;
    String? firstErrorKey;
    final allComponents = _getAllComponents();

    for (var component in allComponents) {
      if (component.type == FormConstants.typeButton) continue;
      if (!isComponentVisible(component)) continue;

      final value = values[component.key];
      final stringValue = value?.toString() ?? '';

      if (!_validateComponent(component, value, stringValue)) {
        isValid = false;
        firstErrorKey ??= component.key;
      }
    }

    if (firstErrorKey != null) {
      _focusNodes[firstErrorKey]?.requestFocus();
    }

    notifyListeners();
    return isValid;
  }

  bool validateStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= config.steps.length) return false;

    final step = config.steps[stepIndex];
    bool isValid = true;
    String? firstErrorKey;

    for (var component in step.components) {
      if (_errors.containsKey(component.key)) {
        _errors.remove(component.key);
      }

      if (component.type == FormConstants.typeButton) continue;
      if (!isComponentVisible(component)) continue;

      final value = values[component.key];
      final stringValue = value?.toString() ?? '';

      if (!_validateComponent(component, value, stringValue)) {
        isValid = false;
        firstErrorKey ??= component.key;
      }
    }

    if (firstErrorKey != null) {
      _focusNodes[firstErrorKey]?.requestFocus();
    }

    notifyListeners();
    return isValid;
  }

  // Helper to allow iteration of all components
  List<FormComponent> _getAllComponents() {
    // Logic duplicated from StateMixin or Config helper.
    // Ideally FormConfig has this helper.
    final comps = [...config.components];
    for (var s in config.steps) {
      comps.addAll(s.components);
    }
    return comps;
  }

  bool _validateComponent(
      FormComponent component, dynamic value, String stringValue) {
    _errors.remove(component.key);

    bool isValueEmpty = false;

    if (value == null) {
      isValueEmpty = true;
    } else if (value is String && value.trim().isEmpty) {
      isValueEmpty = true;
    } else if (value is Iterable) {
      if (value.isEmpty) {
        isValueEmpty = true;
      } else if (value.every((e) => e is FileData)) {
        // For multiple files, all must be successfully uploaded
        isValueEmpty = value.any((e) => !(e as FileData).isUploaded);
      }
    } else if (value is FileData) {
      // For single file, it must be successfully uploaded
      isValueEmpty = !value.isUploaded;
    }

    ValidationRule? requiredRule;
    try {
      requiredRule = component.validation.firstWhere(
        (r) => r.type == FormConstants.validationRequired,
      );
    } catch (_) {
      requiredRule = null;
    }

    final bool isRequired = component.required || requiredRule != null;

    if (isValueEmpty) {
      if (isRequired) {
        _errors[component.key] = requiredRule?.message ??
            FormConstants.requiredMessage(component.label);
        return false;
      }
      return true;
    }

    bool isValid = true;
    for (var rule in component.validation) {
      switch (rule.type) {
        case FormConstants.validationMinLength:
          final min = rule.value as int?;
          if (min != null && stringValue.length < min) {
            _errors[component.key] = rule.message;
            isValid = false;
          }
          break;
        case FormConstants.validationMaxLength:
          final max = rule.value as int?;
          if (max != null && stringValue.length > max) {
            _errors[component.key] = rule.message;
            isValid = false;
          }
          break;
        case FormConstants.validationPattern:
          final pattern = rule.value as String?;
          if (pattern != null && stringValue.isNotEmpty) {
            final regExp = RegExp(pattern);
            if (!regExp.hasMatch(stringValue)) {
              _errors[component.key] = rule.message;
              isValid = false;
            }
          }
          break;
        case FormConstants.validationRequired:
          if (isValueEmpty) {
            _errors[component.key] = rule.message;
            isValid = false;
          }
          break;
      }
      if (!isValid) break;
    }

    if (isValid && component is NumberComponent) {
      if (stringValue.isNotEmpty) {
        final numVal = num.tryParse(stringValue);
        if (numVal != null) {
          if (component.min != null && numVal < component.min!) {
            _errors[component.key] = 'Minimum value is ${component.min}';
            isValid = false;
          }
          if (isValid && component.max != null && numVal > component.max!) {
            _errors[component.key] = 'Maximum value is ${component.max}';
            isValid = false;
          }
        }
      }
    }

    return isValid;
  }
}
