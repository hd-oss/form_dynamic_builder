import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../mixins/data_source_mixin.dart';

class CheckboxLogic extends ChangeNotifier with DataSourceMixin {
  final CheckboxComponent component;
  final FormController formController;

  CheckboxLogic(this.component, this.formController) {
    initDefaultValue(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
  }

  bool get value =>
      (formController.getValue(component.key) ?? component.defaultValue) ==
      true;

  void onChanged(bool? newValue) {
    if (!component.disabled) {
      formController.updateValue(component.key, newValue);
    }
  }

  @override
  void dispose() {
    disposeDataSource();
    super.dispose();
  }
}
