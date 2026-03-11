import 'package:flutter/material.dart';

import '../models/form_component.dart';
import '../utils/form_constants.dart';

/// A reusable label widget for all form field components.
/// Displays the label text with a required indicator and
/// an optional tooltip icon for the description.
class FieldLabel extends StatelessWidget {
  final FormComponent component;

  const FieldLabel({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              text: component.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              children: [
                if (component.required ||
                    component.validation
                        .any((r) => r.type == FormConstants.validationRequired))
                  const TextSpan(
                    text: FormConstants.requiredSuffix,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (component.description.isNotEmpty) ...[
            const SizedBox(width: 4),
            Tooltip(
                message: component.description,
                triggerMode: TooltipTriggerMode.tap,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                )),
          ],
        ],
      ),
    );
  }
}
