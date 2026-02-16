import 'package:flutter/material.dart';
import '../models/form_component.dart';
import '../models/components/all_components.dart';
import '../controller/form_controller.dart';
import '../widgets/fields/text_field_widget.dart';
import '../widgets/fields/checkbox_widget.dart';
import '../widgets/fields/choice_widget.dart';
import '../widgets/fields/button_widget.dart';
import '../widgets/fields/misc_widgets.dart';

typedef WidgetBuilderFunc = Widget Function(
    FormComponent component, FormController controller);

class ComponentRegistry {
  final Map<String, WidgetBuilderFunc> _registry = {};

  ComponentRegistry() {
    _registerDefaultComponents();
  }

  void register(String type, WidgetBuilderFunc builder) {
    _registry[type] = builder;
  }

  Widget build(FormComponent component, FormController controller) {
    final builder = _registry[component.type];
    if (builder != null) {
      return builder(component, controller);
    }
    // Fallback
    return ListTile(
      title: Text('Unknown component type: ${component.type}'),
      subtitle: Text('Key: ${component.key}'),
    );
  }

  void _registerDefaultComponents() {
    register(
        'textfield',
        (c, ctrl) => DynamicTextField(
            component: c as TextFieldComponent, controller: ctrl));
    register(
        'textarea',
        (c, ctrl) => DynamicTextField(
            component: c as TextAreaComponent,
            controller: ctrl,
            maxLines: (c as TextAreaComponent).rows));
    register(
        'number',
        (c, ctrl) => DynamicTextField(
            component: c as NumberComponent,
            controller: ctrl,
            keyboardType: TextInputType.number));
    register(
        'password',
        (c, ctrl) => DynamicTextField(
            component: c as PasswordComponent,
            controller: ctrl,
            obscureText: (c as PasswordComponent)
                .showToggle)); // Logic for showToggle can be added inside widget
    register(
        'currency',
        (c, ctrl) => DynamicTextField(
            component: c as CurrencyComponent,
            controller: ctrl,
            keyboardType: TextInputType.numberWithOptions(
                decimal: true))); // Enhanced Currency widget can be used later

    register(
        'checkbox',
        (c, ctrl) => DynamicCheckbox(
            component: c as CheckboxComponent, controller: ctrl));
    register(
        'select',
        (c, ctrl) =>
            DynamicSelect(component: c as SelectComponent, controller: ctrl));
    register(
        'radio',
        (c, ctrl) =>
            DynamicRadio(component: c as RadioComponent, controller: ctrl));

    register(
        'datetime',
        (c, ctrl) => DynamicDateTime(
            component: c as DateTimeComponent, controller: ctrl));
    register(
        'file',
        (c, ctrl) =>
            DynamicFile(component: c as FileComponent, controller: ctrl));
    register(
        'signature',
        (c, ctrl) => DynamicSignature(
            component: c as SignatureComponent, controller: ctrl));

    register(
        'button',
        (c, ctrl) =>
            DynamicButton(component: c as ButtonComponent, controller: ctrl));
  }
}
