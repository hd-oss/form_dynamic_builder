import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../mixins/data_source_mixin.dart';

class TagsFieldLogic extends ChangeNotifier with DataSourceMixin {
  final TagsComponent component;
  final FormController formController;

  late TextEditingController textController;
  List<String> tags = [];

  TagsFieldLogic(this.component, this.formController) {
    textController = TextEditingController();
    _initTags();

    formController.addListener(_onFormControllerChanged);

    initDefaultValue(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
  }

  void _onFormControllerChanged() {
    _initTags();
    notifyListeners();
  }

  void _initTags() {
    final value = formController.getValue(component.key);
    if (value is List) {
      tags = value.map((e) => e.toString()).toList();
    } else if (value is String && value.isNotEmpty) {
      if (component.storeAs == 'string') {
        tags = value.split(',').map((e) => e.trim()).toList();
      } else {
        tags = [value];
      }
    } else {
      tags = [];
    }
  }

  void _updateController() {
    dynamic valueToStore;
    if (component.storeAs == 'string') {
      valueToStore = tags.join(', ');
    } else {
      valueToStore = List<String>.from(tags);
    }
    formController.updateValue(component.key, valueToStore);
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
      _updateController();
      notifyListeners();
    }
    textController.clear();
  }

  void removeTag(String tag) {
    tags.remove(tag);
    _updateController();
    notifyListeners();
  }

  @override
  void dispose() {
    formController.removeListener(_onFormControllerChanged);
    disposeDataSource();
    textController.dispose();
    super.dispose();
  }
}
