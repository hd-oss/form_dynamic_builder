import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_boxes_component.dart';
import '../../models/components/select_option.dart';
import '../../services/mixins/datasource_mixin.dart';

class SelectBoxesLogic extends ChangeNotifier with DataSourceMixin {
  final SelectBoxesComponent component;
  final FormController formController;

  SelectBoxesLogic(this.component, this.formController) {
    initDataSource(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
  }

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

  /// Returns dynamic options if dataSource is API, otherwise static options.
  List<SelectOption> get allOptions {
    if (component.dataSource != null && component.dataSource!.isDynamic) {
      return dynamicOptions;
    }
    return component.options;
  }

  void updateValue(String optionValue, bool isChecked) {
    if (component.disabled) return;

    final vals = List<String>.from(currentValues);
    if (isChecked) {
      if (!vals.contains(optionValue)) vals.add(optionValue);
    } else {
      vals.remove(optionValue);
    }

    // Build joined label string for answerText
    final labels = vals.map((v) {
      final opt = allOptions.firstWhere(
        (o) => o.value == v,
        orElse: () => SelectOption(label: v, value: v),
      );
      return opt.label;
    }).toList();

    formController.updateValueWithLabel(component.key, vals, labels.join(', '));
  }

  @override
  void dispose() {
    disposeDataSource();
    super.dispose();
  }
}
