import 'package:flutter/material.dart';
import '../../models/components/all_components.dart';
import '../../controller/form_controller.dart';
import 'field_label.dart';

class DynamicRadio extends StatelessWidget {
  final RadioComponent component;
  final FormController controller;

  const DynamicRadio({
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
          final groupValue = controller.getValue(component.key);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                ),
                child: Focus(
                  focusNode: controller.getFocusNode(component.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: component.options.map((option) {
                      return RadioListTile<String>(
                        title: Text(option.label),
                        value: option.value,
                        groupValue: groupValue,
                        onChanged: component.disabled
                            ? null
                            : (String? newValue) {
                                controller.updateValue(component.key, newValue);
                              },
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
