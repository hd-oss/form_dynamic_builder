import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

class DynamicCheckbox extends StatelessWidget {
  final CheckboxComponent component;
  final FormController controller;

  const DynamicCheckbox({
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
          final value =
              controller.getValue(component.key) ?? component.defaultValue;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              InputDecorator(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorText: controller.errors[component.key],
                ),
                child: CheckboxListTile.adaptive(
                  title: Text(component.label),
                  value: value == true,
                  onChanged: component.disabled
                      ? null
                      : (bool? newValue) {
                          controller.updateValue(component.key, newValue);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
