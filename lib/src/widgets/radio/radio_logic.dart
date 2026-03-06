import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../services/mixins/datasource_mixin.dart';

class RadioLogic extends ChangeNotifier with DataSourceMixin {
  final RadioComponent component;
  final FormController formController;

  RadioLogic(this.component, this.formController) {
    initDataSource(
      dataSource: component.dataSource,
      controller: formController,
    );
  }

  String? get groupValue => formController.getValue(component.key) as String?;

  void onChanged(String? newValue) {
    if (!component.disabled) {
      final label = allOptions
          .firstWhere(
            (e) => e.value == newValue,
            orElse: () => SelectOption(label: '', value: ''),
          )
          .label;
      formController.updateValueWithLabel(component.key, newValue, label);
    }
  }

  /// Returns dynamic options if dataSource is API, otherwise static options.
  List<SelectOption> get allOptions {
    if (component.dataSource != null && component.dataSource!.isDynamic) {
      return dynamicOptions;
    }
    return component.options;
  }

  @override
  void dispose() {
    disposeDataSource();
    super.dispose();
  }
}
