import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';

class SelectLogic extends ChangeNotifier {
  final SelectComponent component;
  final FormController formController;

  SelectLogic(this.component, this.formController);

  String? get value => formController.getValue(component.key) as String?;

  void updateValue(String? newValue) {
    if (!component.disabled) {
      formController.updateValue(component.key, newValue);
    }
  }

  SelectOption get selectedOption => component.options.firstWhere(
        (element) => element.value == value,
        orElse: () => SelectOption(label: '', value: ''),
      );

  int get initialIndex {
    int index = component.options.indexWhere((e) => e.value == value);
    if (index == -1) index = 0;
    return index;
  }
}
