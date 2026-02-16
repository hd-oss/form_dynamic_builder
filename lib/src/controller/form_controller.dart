import 'package:flutter/foundation.dart';
import '../models/form_config.dart';

class FormController extends ChangeNotifier {
  final FormConfig config;
  final Map<String, dynamic> _values = {};
  final Map<String, String> _errors = {};

  FormController({required this.config}) {
    _initializeValues();
  }

  Map<String, dynamic> get values => _values;
  Map<String, String> get errors => _errors;

  void _initializeValues() {
    for (var component in config.components) {
      if (component.type == 'button') continue;

      // Initialize with defaults if available, otherwise null
      // We can extend this logic based on component types if needed
      // e.g. Checkbox default value
    }
  }

  void updateValue(String key, dynamic value) {
    _values[key] = value;
    // Clear error when user types
    if (_errors.containsKey(key)) {
      _errors.remove(key);
    }
    notifyListeners();
  }

  dynamic getValue(String key) {
    return _values[key];
  }

  bool validate() {
    _errors.clear();
    bool isValid = true;

    for (var component in config.components) {
      if (component.type == 'button') continue;

      if (component.required) {
        final value = _values[component.key];
        if (value == null || (value is String && value.isEmpty)) {
          _errors[component.key] = '${component.label} is required';
          isValid = false;
        }
      }
    }

    notifyListeners();
    return isValid;
  }

  void reset() {
    _values.clear();
    _errors.clear();
    _initializeValues();
    notifyListeners();
  }
}
