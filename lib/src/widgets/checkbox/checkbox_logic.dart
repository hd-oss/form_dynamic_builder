import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';

class CheckboxLogic extends ChangeNotifier {
  final CheckboxComponent component;
  final FormController formController;

  CheckboxLogic(this.component, this.formController);

  bool get value =>
      (formController.getValue(component.key) ?? component.defaultValue) ==
      true;

  void onChanged(bool? newValue) {
    if (!component.disabled) {
      formController.updateValue(component.key, newValue);
    }
  }
}
