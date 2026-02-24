import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';

class RadioLogic extends ChangeNotifier {
  final RadioComponent component;
  final FormController formController;

  RadioLogic(this.component, this.formController);

  String? get groupValue => formController.getValue(component.key) as String?;

  void onChanged(String? newValue) {
    if (!component.disabled) {
      formController.updateValue(component.key, newValue);
    }
  }
}
