import 'package:flutter/material.dart';

import '../models/form_config.dart';
import 'mixins/form_navigation_mixin.dart';
import 'mixins/form_state_mixin.dart';
import 'mixins/form_validation_mixin.dart';
import 'mixins/form_visibility_mixin.dart';

class FormController extends ChangeNotifier
    with
        FormStateMixin,
        FormVisibilityMixin,
        FormValidationMixin,
        FormNavigationMixin {
  @override
  final FormConfig config;

  final Map<String, dynamic> _dsForm = {};

  /// Access dynamic data provided by the application.
  Map<String, dynamic> get dsForm => _dsForm;

  /// Incremented on every [reset] call.
  /// Used by the form builder to force-rebuild all component widgets.
  int _resetGeneration = 0;
  int get resetGeneration => _resetGeneration;

  FormController({
    required this.config,
  }) {
    if (config.dsForm != null) {
      _dsForm.addAll(config.dsForm!);
    }
    initializeValues();
    // Prime the API cache for conditional logic
    refreshConditionalApiValues().then((_) => notifyListeners());
  }

  /// Updates manually provided dynamic data.
  void updateDsForm(Map<String, dynamic> data) {
    _dsForm.addAll(data);
    notifyListeners();
  }

  /// Clears all values, errors, focus nodes, and resets navigation.
  void reset() {
    _resetGeneration++;
    clearFocusNodes(); // Dispose stale FocusNodes so inputs work again
    initializeValues();
    errors.clear();
    resetNavigation();
    notifyListeners();
  }

  @override
  void dispose() {
    disposeValidationResources(); // ValidationMixin
    super.dispose();
  }
}
