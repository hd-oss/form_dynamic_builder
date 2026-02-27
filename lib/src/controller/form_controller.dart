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

  final Map<String, String> authHeaders;

  final Map<String, dynamic> _dsForm = {};

  /// Access dynamic data provided by the application.
  Map<String, dynamic> get dsForm => _dsForm;

  FormController({
    required this.config,
    this.authHeaders = const {},
  }) {
    if (config.dsForm != null) {
      _dsForm.addAll(config.dsForm!);
    }
    initializeValues();
  }

  /// Updates manually provided dynamic data.
  void updateDsForm(Map<String, dynamic> data) {
    _dsForm.addAll(data);
    notifyListeners();
  }

  /// Clears all values, errors, and resets navigation.
  void reset() {
    // _values is in StateMixin (private there, but we have initializeValues)
    // _currentStep is in NavigationMixin
    // _errors is in ValidationMixin

    // Usage of mixin methods:
    initializeValues(); // StateMixin (clears and reinits)
    // Actually StateMixin.initializeValues clears _values.

    // We need to clear errors.
    errors.clear(); // ValidationMixin exposes errors map.

    resetNavigation(); // NavigationMixin
    notifyListeners();
  }

  @override
  void dispose() {
    disposeValidationResources(); // ValidationMixin
    super.dispose();
  }
}
