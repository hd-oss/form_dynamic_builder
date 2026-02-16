import 'package:flutter/material.dart';
import '../models/form_config.dart';
import '../controller/form_controller.dart';
import '../registry/component_registry.dart';

class FormDynamicBuilder extends StatefulWidget {
  final FormConfig formConfig;
  final FormController? controller;
  final ComponentRegistry? registry;
  final Function(Map<String, dynamic>)? onSubmit;

  const FormDynamicBuilder({
    Key? key,
    required this.formConfig,
    this.controller,
    this.registry,
    this.onSubmit,
  }) : super(key: key);

  @override
  _FormDynamicBuilderState createState() => _FormDynamicBuilderState();
}

class _FormDynamicBuilderState extends State<FormDynamicBuilder> {
  late FormController _controller;
  late ComponentRegistry _registry;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? FormController(config: widget.formConfig);
    _registry = widget.registry ?? ComponentRegistry();

    // Override default submit action if provided
    /*
    If we want to intercept the button submit, we might need to handle it in the controller 
    or pass the callback to the button widget.
    For now, DynamicButton calls controller.validate() and then we can have a listener or callback.
    But DynamicButton in generic registry implementation might need a way to bubble up the event.
    Simple solution: Passing `onSubmit` down to the button via some context or special handling?
    The current `DynamicButton` accepts `onSubmit` but `ComponentRegistry` construction of it doesn't pass it yet.
    I will need to modify the registry or how we build the button.
    */
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.formConfig.title.isNotEmpty)
              Text(
                widget.formConfig.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            if (widget.formConfig.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  widget.formConfig.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ...widget.formConfig.components.map((component) {
              // Special handling for passing onSubmit to button
              if (component.type == 'button' && widget.onSubmit != null) {
                // We need a way to pass this.
                // One way is to check the type here and manually build if we want to override,
                // OR update the registry to allow passing extra args.
                // For now, let's just use the registry. The registry logic for button might need an update.
                // Since ComponentRegistry is hardcoded for now, I can't easily pass the callback without modification.
                // I will modify ComponentRegistry to accept an override or just manually handle button here?
                // Better: Modify ComponentRegistry.build to accept an optional 'onAction' callback map.
              }

              // Temporary hack: if it's a button, we might want to wrap it or inject logic.
              // But strictly speaking, the controller should handle submission or the button widget should trigger a callback.
              // Let's rely on the registry for now.
              Widget widgetBuilt = _registry.build(component, _controller);

              // If it is a button, we want to hook into it.
              // Since we can't easily hook into the widget built by registry without context,
              // we can update the registry definition for 'button' in `initState` if we expose `register`.

              return widgetBuilt;
            }).toList(),
          ],
        ),
      ),
    );
  }
}
