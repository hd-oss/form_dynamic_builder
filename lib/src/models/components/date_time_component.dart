import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class DateTimeComponent extends FormComponent {
  final bool enableTime;

  DateTimeComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.description,
    super.required,
    super.disabled,
    super.hidden,
    super.textTransform,
    super.inputMask,
    super.validation,
    super.conditional,
    super.defaultValue,
    this.enableTime = false,
  });

  factory DateTimeComponent.fromJson(Map<String, dynamic> json) {
    return DateTimeComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      description: json['description'] ?? '',
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      textTransform: json['textTransform'] ?? 'none',
      inputMask: json['inputMask'] ?? '',
      validation: (json['validation'] as List?)
              ?.map((e) => ValidationRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      conditional: parseConditional(json),
      defaultValue: json['defaultValue'],
      enableTime: json['enableTime'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['enableTime'] = enableTime;
    return json;
  }
}
