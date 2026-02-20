import 'package:flutter/material.dart';
import '../../controller/form_controller.dart';
import '../../models/components/select_boxes_component.dart';
import 'field_label.dart';

class SelectBoxesWidget extends StatelessWidget {
  final SelectBoxesComponent component;
  final FormController controller;

  const SelectBoxesWidget({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final currentValues = _getCurrentValues();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              if (component.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    component.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ...component.options.map((option) {
                final isSelected = currentValues.contains(option.value);
                return CheckboxListTile.adaptive(
                  title: Text(option.label),
                  value: isSelected,
                  onChanged: component.disabled
                      ? null
                      : (bool? checked) {
                          _updateValue(option.value, checked ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              if (controller.errors.containsKey(component.key))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    controller.errors[component.key]!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<String> _getCurrentValues() {
    final value = controller.getValue(component.key);
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    // Handle single value legacy/migration if needed
    if (value != null) {
      return [value.toString()];
    }
    return [];
  }

  void _updateValue(String optionValue, bool isChecked) {
    final currentValues = _getCurrentValues();
    final newValues = List<String>.from(currentValues);

    if (isChecked) {
      if (!newValues.contains(optionValue)) {
        newValues.add(optionValue);
      }
    } else {
      newValues.remove(optionValue);
    }

    controller.updateValue(component.key, newValues);
  }
}
