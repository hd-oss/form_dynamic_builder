import 'package:flutter/material.dart';
import '../../models/components/input_components.dart';
import '../../controller/form_controller.dart';

class DynamicDateTime extends StatelessWidget {
  final DateTimeComponent component;
  final FormController controller;

  const DynamicDateTime({
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
          final value = controller.getValue(component.key);
          final textController =
              TextEditingController(text: value?.toString() ?? '');

          return TextFormField(
            controller: textController,
            decoration: InputDecoration(
              labelText: component.label + (component.required ? ' *' : ''),
              hintText: component.placeholder,
              border: OutlineInputBorder(),
              errorText: controller.errors[component.key],
              suffixIcon: Icon(Icons.calendar_today),
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
                      // Format suitable for backend, e.g., ISO8601
                      controller.updateValue(component.key,
                          pickedDate.toIso8601String().split('T')[0]);
                    }
                  },
          );
        },
      ),
    );
  }
}

class DynamicFile extends StatelessWidget {
  final FileComponent component;
  final FormController controller;

  const DynamicFile({
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
          final value = controller.getValue(component.key);

          return InputDecorator(
            decoration: InputDecoration(
              labelText: component.label + (component.required ? ' *' : ''),
              border: OutlineInputBorder(),
              errorText: controller.errors[component.key],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value != null) Text('Selected: $value'),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: component.disabled
                      ? null
                      : () {
                          // Mock file picking
                          controller.updateValue(
                              component.key, "dummy_file.pdf");
                        },
                  icon: Icon(Icons.upload_file),
                  label: Text('Upload File'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class DynamicSignature extends StatelessWidget {
  final SignatureComponent component;
  final FormController controller;

  const DynamicSignature({
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
          return InputDecorator(
            decoration: InputDecoration(
              labelText: component.label + (component.required ? ' *' : ''),
              border: OutlineInputBorder(),
              errorText: controller.errors[component.key],
            ),
            child: Container(
              height: component.height ?? 150,
              width: component.width ?? double.infinity,
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: Text('Signature Pad Placeholder',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}
