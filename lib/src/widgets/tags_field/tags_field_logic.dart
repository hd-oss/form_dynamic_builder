import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../services/mixins/datasource_mixin.dart';

class TagsFieldLogic extends ChangeNotifier with DataSourceMixin {
  final TagsComponent component;
  final FormController formController;

  late TextEditingController textController;
  List<String> tags = [];

  List<SelectOption> suggestions = [];

  TagsFieldLogic(this.component, this.formController) {
    textController = TextEditingController();
    _initTags();

    formController.addListener(_onFormControllerChanged);

    initDataSource(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
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

    // Build joined label for answerText
    final labels = tags.map((tag) {
      final opt = dynamicOptions.isNotEmpty
          ? dynamicOptions.firstWhere(
              (o) => o.value == tag,
              orElse: () => SelectOption(label: tag, value: tag),
            )
          : SelectOption(label: tag, value: tag);
      return opt.label;
    }).toList();

    formController.updateValueWithLabel(
        component.key, valueToStore, labels.join(', '));
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      if (component.maxTags != null && tags.length >= component.maxTags!) {
        // Limit reached, do not add
        textController.clear();
        clearSuggestions();
        return;
      }
      tags.add(tag);
      _updateController();
      notifyListeners();
    }
    textController.clear();
    clearSuggestions();
  }

  void removeTag(String tag) {
    tags.remove(tag);
    _updateController();
    notifyListeners();
  }

  void fetchSuggestions(String query) {
    if (query.isEmpty) {
      clearSuggestions();
      return;
    }

    // Split query into individual alphanumeric words to allow detached multi-word queries
    // like "harry s" to match "harry potter and the sorcerer's stone"
    final queryTerms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    suggestions = dynamicOptions.where((option) {
      final labelLower = option.label.toLowerCase();
      final valueLower = option.value.toLowerCase();

      // Ensure every word typed by the user exists in either the label or the value
      return queryTerms.every(
          (term) => labelLower.contains(term) || valueLower.contains(term));
    }).toList();

    notifyListeners();
  }

  void clearSuggestions() {
    if (suggestions.isNotEmpty) {
      suggestions = [];
      notifyListeners();
    }
  }

  void selectSuggestion(SelectOption option) {
    addTag(option.value);
  }

  @override
  void dispose() {
    formController.removeListener(_onFormControllerChanged);
    disposeDataSource();
    textController.dispose();
    super.dispose();
  }
}
