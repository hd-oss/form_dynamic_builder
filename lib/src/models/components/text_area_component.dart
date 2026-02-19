import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class TextAreaComponent extends FormComponent {
  final int rows;

  TextAreaComponent({
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
    this.rows = 3,
  });

  factory TextAreaComponent.fromJson(Map<String, dynamic> json) {
    return TextAreaComponent(
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
      rows: json['rows'] ?? 3,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['rows'] = rows;
    return json;
  }
}
