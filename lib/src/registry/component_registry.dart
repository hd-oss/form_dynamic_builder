import 'package:flutter/material.dart';

import '../controller/form_controller.dart';
import '../models/components/all_components.dart';
import '../models/form_component.dart';
import '../utils/form_constants.dart';
import '../widgets/camera/camera_fied_widget.dart';
import '../widgets/date_time/date_time_widget.dart';
import '../widgets/checkbox/checkbox_widget.dart';
import '../widgets/file/file_widget.dart';
import '../widgets/radio/radio_widget.dart';
import '../widgets/select_boxes/select_boxes_widget.dart';
import '../widgets/select/select_widget.dart';
import '../widgets/location/location_widget.dart';
import '../widgets/signature/signature_widget.dart';
import '../widgets/tags_field/tags_field_widget.dart';
import '../widgets/text_field/text_field_widget.dart';

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

  void _registerUnknownComponent() {
    register(FormConstants.typeUnknown, (c, ctrl) => const SizedBox.shrink());
  }

  Widget build(FormComponent component, FormController controller) {
    final builder = _registry[component.type];
    if (builder != null) {
      return builder(component, controller);
    }
    // Fallback: Return an empty widget ("komponen kosong")
    return const SizedBox.shrink();
  }

  void _registerDefaultComponents() {
    _registerUnknownComponent();
    register(
        FormConstants.typeTextField,
        (c, ctrl) => DynamicTextField(
              component: c as TextFieldComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeTextArea,
        (c, ctrl) => DynamicTextField(
            component: c as TextAreaComponent,
            controller: ctrl,
            maxLines: (c).rows));
    register(
        FormConstants.typeNumber,
        (c, ctrl) => DynamicTextField(
            component: c as NumberComponent,
            controller: ctrl,
            keyboardType: TextInputType.number));
    register(
        FormConstants.typePassword,
        (c, ctrl) => DynamicTextField(
            component: c as PasswordComponent,
            controller: ctrl,
            obscureText: (c).showToggle));
    register(
        FormConstants.typeCurrency,
        (c, ctrl) => DynamicTextField(
            component: c as CurrencyComponent,
            controller: ctrl,
            keyboardType: TextInputType.number));
    register(
        FormConstants.typeCheckbox,
        (c, ctrl) => DynamicCheckbox(
              component: c as CheckboxComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeSelect,
        (c, ctrl) => DynamicSelect(
              component: c as SelectComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeSelectBoxes,
        (c, ctrl) => SelectBoxesWidget(
              component: c as SelectBoxesComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeRadio,
        (c, ctrl) => DynamicRadio(
              component: c as RadioComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeDateTime,
        (c, ctrl) => DynamicDateTime(
              component: c as DateTimeComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeFile,
        (c, ctrl) => DynamicFile(
              component: c as FileComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeSignature,
        (c, ctrl) => DynamicSignature(
              component: c as SignatureComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeTags,
        (c, ctrl) => TagsFieldWidget(
              component: c as TagsComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeCamera,
        (c, ctrl) => DynamicCamera(
              component: c as CameraComponent,
              controller: ctrl,
            ));
    register(
        FormConstants.typeLocation,
        (c, ctrl) => DynamicLocation(
              component: c as LocationComponent,
              controller: ctrl,
            ));
  }
}
