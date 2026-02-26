import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';
import 'select_option.dart';

class SelectBoxesComponent extends FormComponent {
  final List<SelectOption> options;
  final bool inline;

  SelectBoxesComponent({
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
    super.dataSource,
    super.platforms,
    this.options = const [],
    this.inline = false,
  });

  factory SelectBoxesComponent.fromJson(Map<String, dynamic> json) {
    return SelectBoxesComponent(
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
      defaultValue: json['defaultValue'], // Might be null or list
      dataSource: parseDataSource(json),
      platforms: json['platforms'],
      options: (json['options'] as List?)
              ?.map((e) => SelectOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      inline: json['inline'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['options'] = options.map((e) => e.toJson()).toList();
    json['inline'] = inline;
    if (defaultValue != null) json['defaultValue'] = defaultValue;
    return json;
  }
}
