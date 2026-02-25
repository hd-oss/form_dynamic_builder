import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';
import 'select_option.dart';

class RadioComponent extends FormComponent {
  final List<SelectOption> options;

  RadioComponent({
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
    this.options = const [],
  });

  factory RadioComponent.fromJson(Map<String, dynamic> json) {
    var optionsList = <SelectOption>[];
    if (json['options'] != null) {
      optionsList = (json['options'] as List)
          .map((e) => SelectOption.fromJson(e))
          .toList();
    }
    return RadioComponent(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      key: json['key'] ?? '',
      label: json['label'] ?? '',
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
      options: optionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['options'] = options.map((e) => e.toJson()).toList();
    return json;
  }
}
