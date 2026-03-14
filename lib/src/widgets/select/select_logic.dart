import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../services/mixins/datasource_mixin.dart';

class SelectLogic extends ChangeNotifier with DataSourceMixin {
  final SelectComponent component;
  final FormController formController;

  late TextEditingController textController;
  List<SelectOption> filteredOptions = [];

  SelectLogic(this.component, this.formController) {
    textController = TextEditingController(text: selectedOption.label);
    filteredOptions = allOptions;

    initDataSource(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );

    formController.addListener(_onFormControllerChanged);
  }

  void _onFormControllerChanged() {
    if (textController.text != selectedOption.label) {
      textController.text = selectedOption.label;
    }
    notifyListeners();
  }

  String? get value => formController.getValue(component.key) as String?;

  void updateValue(String? newValue) {
    if (!component.disabled) {
      final option = allOptions.firstWhere(
        (e) => e.value == newValue,
        orElse: () => SelectOption(label: '', value: ''),
      );
      formController.updateValueWithLabel(
          component.key, newValue, option.label);
      textController.text = option.label;
      clearSuggestions();
    }
  }

  void fetchSuggestions(String query) {
    if (query.isEmpty) {
      filteredOptions = allOptions;
    } else {
      final queryLower = query.toLowerCase();
      filteredOptions = allOptions.where((option) {
        return option.label.toLowerCase().contains(queryLower) ||
            option.value.toLowerCase().contains(queryLower);
      }).toList();
    }
    notifyListeners();
  }

  void clearSuggestions() {
    filteredOptions = allOptions;
    notifyListeners();
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
    formController.removeListener(_onFormControllerChanged);
    disposeDataSource();
    textController.dispose();
    super.dispose();
  }
}
