import 'package:flutter/material.dart';
import '../../models/components/all_components.dart';
import '../../controller/form_controller.dart';
import 'field_label.dart';

class DynamicSelect extends StatelessWidget {
  final SelectComponent component;
  final FormController controller;

  const DynamicSelect({
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              DropdownButtonFormField<String>(
                focusNode: controller.getFocusNode(component.key),
                value: controller.getValue(component.key),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                ),
                items: component.options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  );
                }).toList(),
                onChanged: component.disabled
                    ? null
                    : (String? newValue) {
                        controller.updateValue(component.key, newValue);
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
