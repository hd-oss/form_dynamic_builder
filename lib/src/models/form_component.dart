import 'components/all_components.dart';

abstract class FormComponent {
  final String id;
  final String type;
  final String key;
  final String label;
  final String? placeholder;
  final bool required;
  final bool disabled;
  final bool hidden;

  FormComponent({
    required this.id,
    required this.type,
    required this.key,
    required this.label,
    this.placeholder,
    this.required = false,
    this.disabled = false,
    this.hidden = false,
  });

  factory FormComponent.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'textfield':
        return TextFieldComponent.fromJson(json);
      case 'textarea':
        return TextAreaComponent.fromJson(json);
      case 'number':
        return NumberComponent.fromJson(json);
      case 'password':
        return PasswordComponent.fromJson(json);
      case 'checkbox':
        return CheckboxComponent.fromJson(json);
      case 'select':
        return SelectComponent.fromJson(json);
      case 'radio':
        return RadioComponent.fromJson(json);
      case 'datetime':
        return DateTimeComponent.fromJson(json);
      case 'currency':
        return CurrencyComponent.fromJson(json);
      case 'file':
        return FileComponent.fromJson(json);
      case 'signature':
        return SignatureComponent.fromJson(json);
      case 'button':
        return ButtonComponent.fromJson(json);
      default:
        // Fallback or unknown component
        return TextFieldComponent.fromJson(json);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'key': key,
      'label': label,
      if (placeholder != null) 'placeholder': placeholder,
      'required': required,
      'disabled': disabled,
      'hidden': hidden,
    };
  }
}
