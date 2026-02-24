import '../utils/form_constants.dart';
import 'components/all_components.dart';
import 'conditional_config.dart';
import 'validation_rule.dart';

abstract class FormComponent {
  final String id;
  final String type;
  final String key;
  final String label;
  final String? placeholder;
  final String description;
  final bool required;
  final bool disabled;
  final bool hidden;
  final String textTransform;
  final String inputMask;
  final List<ValidationRule> validation;
  final ConditionalConfig? conditional;
  final dynamic defaultValue;

  FormComponent({
    required this.id,
    required this.type,
    required this.key,
    required this.label,
    this.placeholder,
    this.description = '',
    this.required = false,
    this.disabled = false,
    this.hidden = false,
    this.textTransform = FormConstants.transformNone,
    this.inputMask = '',
    this.validation = const [],
    this.conditional,
    this.defaultValue,
  });

  factory FormComponent.fromJson(Map<String, dynamic> json) {
    final type = json['type'];

    switch (type) {
      case FormConstants.typeTextField:
        return TextFieldComponent.fromJson(json);
      case FormConstants.typeTextArea:
        return TextAreaComponent.fromJson(json);
      case FormConstants.typeNumber:
        return NumberComponent.fromJson(json);
      case FormConstants.typePassword:
        return PasswordComponent.fromJson(json);
      case FormConstants.typeCheckbox:
        return CheckboxComponent.fromJson(json);
      case FormConstants.typeSelect:
        return SelectComponent.fromJson(json);
      case FormConstants.typeSelectBoxes:
        return SelectBoxesComponent.fromJson(json);
      case FormConstants.typeRadio:
        return RadioComponent.fromJson(json);
      case FormConstants.typeDateTime:
        return DateTimeComponent.fromJson(json);
      case FormConstants.typeCurrency:
        return CurrencyComponent.fromJson(json);
      case FormConstants.typeFile:
        return FileComponent.fromJson(json);
      case FormConstants.typeSignature:
        return SignatureComponent.fromJson(json);
      case FormConstants.typeTags:
        return TagsComponent.fromJson(json);
      case FormConstants.typeCamera:
        return CameraComponent.fromJson(json);
      case FormConstants.typeLocation:
        return LocationComponent.fromJson(json);
      default:
        return UnknownComponent.fromJson(json);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'key': key,
      'label': label,
      if (placeholder != null) 'placeholder': placeholder,
      'description': description,
      'required': required,
      'disabled': disabled,
      'hidden': hidden,
      'textTransform': textTransform,
      'inputMask': inputMask,
      'validation': validation.map((e) => e.toJson()).toList(),
      if (conditional != null) 'conditional': conditional!.toJson(),
      if (defaultValue != null) 'defaultValue': defaultValue,
    };
  }
}
