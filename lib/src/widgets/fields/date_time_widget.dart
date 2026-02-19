import 'package:flutter/material.dart';
import '../../models/components/all_components.dart';
import '../../controller/form_controller.dart';
import 'field_label.dart';

class DynamicDateTime extends StatelessWidget {
  final DateTimeComponent component;
  final FormController controller;

  const DynamicDateTime({
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
          final value = controller.getValue(component.key);
          final textController =
              TextEditingController(text: value?.toString() ?? '');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              TextFormField(
                focusNode: controller.getFocusNode(component.key),
                controller: textController,
                decoration: InputDecoration(
                  hintText: component.placeholder,
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: component.disabled
                    ? null
                    : () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          controller.updateValue(component.key,
                              pickedDate.toIso8601String().split('T')[0]);
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
