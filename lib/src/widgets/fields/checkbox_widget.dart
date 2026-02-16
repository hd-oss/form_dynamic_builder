import 'package:flutter/material.dart';
import '../../models/components/choice_components.dart';
import '../../controller/form_controller.dart';

class DynamicCheckbox extends StatelessWidget {
  final CheckboxComponent component;
  final FormController controller;

  const DynamicCheckbox({
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
          final value =
              controller.getValue(component.key) ?? component.defaultValue;
          return InputDecorator(
            decoration: InputDecoration(
              border: InputBorder.none,
              errorText: controller.errors[component.key],
            ),
            child: CheckboxListTile(
              title: Text(component.label + (component.required ? ' *' : '')),
              value: value == true,
              onChanged: component.disabled
                  ? null
                  : (bool? newValue) {
                      controller.updateValue(component.key, newValue);
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          );
        },
      ),
    );
  }
}
