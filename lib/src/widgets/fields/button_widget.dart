import 'package:flutter/material.dart';
import '../../models/components/action_components.dart';
import '../../controller/form_controller.dart';

class DynamicButton extends StatelessWidget {
  final ButtonComponent component;
  final FormController controller;
  final VoidCallback? onSubmit;

  const DynamicButton({
    Key? key,
    required this.component,
    required this.controller,
    this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: component.disabled
              ? null
              : () {
                  if (component.action == 'submit') {
                    if (controller.validate()) {
                      onSubmit?.call();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Please fix the errors in the form.')),
                      );
                    }
                  } else if (component.action == 'reset') {
                    controller.reset();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: component.theme == 'primary'
                ? Theme.of(context).primaryColor
                : null,
          ),
          child: Text(component.label),
        ),
      ),
    );
  }
}
