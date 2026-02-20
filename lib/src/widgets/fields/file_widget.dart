import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

class DynamicFile extends StatelessWidget {
  final FileComponent component;
  final FormController controller;

  const DynamicFile({
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
                    children: [
                      if (value != null) Text('Selected: $value'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: component.disabled
                            ? null
                            : () {
                                controller.updateValue(
                                    component.key, "dummy_file.pdf");
                              },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload File'),
                      )
                    ],
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
