import 'package:flutter/material.dart';
import '../../models/components/all_components.dart';
import '../../controller/form_controller.dart';
import 'field_label.dart';

class DynamicSignature extends StatelessWidget {
  final SignatureComponent component;
  final FormController controller;

  const DynamicSignature({
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
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                ),
                child: Focus(
                  focusNode: controller.getFocusNode(component.key),
                  child: Container(
                    height: component.height ?? 150,
                    width: component.width ?? double.infinity,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Text('Signature Pad Placeholder',
                        style: TextStyle(color: Colors.grey)),
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
