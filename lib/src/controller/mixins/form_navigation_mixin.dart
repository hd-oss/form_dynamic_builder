import 'package:flutter/material.dart';
import '../../models/form_config.dart';

mixin FormNavigationMixin on ChangeNotifier {
  // Expected Members from FormController
  FormConfig get config;
  bool validateStep(int stepIndex);

  int _currentStep = 0;
  int get currentStep => _currentStep;

  void resetNavigation() {
    _currentStep = 0;
  }

  /// Move to the next step if validation passes for the current step
  bool nextStep() {
    if (validateStep(_currentStep)) {
      if (_currentStep < config.steps.length - 1) {
        _currentStep++;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Move to the previous step
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Jump to a specific step
  void goToStep(int step) {
    if (step >= 0 && step < config.steps.length) {
      _currentStep = step;
      notifyListeners();
    }
  }
}
