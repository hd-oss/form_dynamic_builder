import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_boxes_component.dart';

class SelectBoxesLogic extends ChangeNotifier {
  final SelectBoxesComponent component;
  final FormController formController;

  SelectBoxesLogic(this.component, this.formController);

  List<String> get currentValues {
    final value = formController.getValue(component.key);
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value != null) {
      return [value.toString()];
    }
    return [];
  }

  void updateValue(String optionValue, bool isChecked) {
    if (component.disabled) return;

    final vals = List<String>.from(currentValues);
    if (isChecked) {
      if (!vals.contains(optionValue)) vals.add(optionValue);
    } else {
      vals.remove(optionValue);
    }
    formController.updateValue(component.key, vals);
  }
}
