import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../services/mixins/datasource_mixin.dart';

class SelectLogic extends ChangeNotifier with DataSourceMixin {
  final SelectComponent component;
  final FormController formController;

  SelectLogic(this.component, this.formController) {
    initDataSource(
      dataSource: component.dataSource,
      controller: formController,
    );
  }

  String? get value => formController.getValue(component.key) as String?;

  void updateValue(String? newValue) {
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

  SelectOption get selectedOption => allOptions.firstWhere(
        (element) => element.value == value,
        orElse: () => SelectOption(label: '', value: ''),
      );

  int get initialIndex {
    int index = allOptions.indexWhere((e) => e.value == value);
    if (index == -1) index = 0;
    return index;
  }

  @override
  void dispose() {
    disposeDataSource();
    super.dispose();
  }
}
