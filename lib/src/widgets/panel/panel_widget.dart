import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/form_component.dart';
import '../../models/components/all_components.dart';

class PanelWidget extends StatelessWidget {
  final PanelComponent component;
  final FormController controller;
  // This builder function allows the registry to provide the widget builder
  // without creating a circular dependency loop backwards into the registry.
  final Widget Function(FormComponent) componentBuilder;

  const PanelWidget({
    super.key,
    required this.component,
    required this.controller,
    required this.componentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: component.theme == 'default' ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: component.theme == 'primary'
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide(color: theme.dividerColor),
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (component.label.isNotEmpty) ...[
                Text(
                  component.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (component.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    component.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],
              ...component.components.map((childComp) {
                return ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    if (!controller.isComponentVisible(childComp)) {
                      return const SizedBox.shrink();
                    }
                    return componentBuilder(childComp);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
