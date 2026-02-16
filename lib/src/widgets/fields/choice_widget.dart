import 'package:flutter/material.dart';
import '../../models/components/choice_components.dart';
import '../../controller/form_controller.dart';

class DynamicSelect extends StatelessWidget {
  final SelectComponent component;
  final FormController controller;

  const DynamicSelect({
    Key? key,
    required this.component,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return DropdownButtonFormField<String>(
            value: controller.getValue(component.key),
            decoration: InputDecoration(
              labelText: component.label + (component.required ? ' *' : ''),
              border: OutlineInputBorder(),
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
          );
        },
      ),
    );
  }
}

class DynamicRadio extends StatelessWidget {
  final RadioComponent component;
  final FormController controller;

  const DynamicRadio({
    Key? key,
    required this.component,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final groupValue = controller.getValue(component.key);

          return InputDecorator(
            decoration: InputDecoration(
              labelText: component.label + (component.required ? ' *' : ''),
              border: OutlineInputBorder(),
              errorText: controller.errors[component.key],
            ),
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
          );
        },
      ),
    );
  }
}
