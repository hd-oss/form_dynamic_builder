import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';
import 'select_option.dart';

class SelectComponent extends FormComponent {
  final List<SelectOption> options;
  final String? calculation;

  SelectComponent({
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
    super.platforms,
    super.dataSource,
    super.destinationTable,
    super.destinationColumn,
    this.options = const [],
    this.calculation,
  });

  factory SelectComponent.fromJson(Map<String, dynamic> json) {
    return SelectComponent(
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
      platforms: json['platforms'],
      options: (json['options'] as List?)
              ?.map((e) => SelectOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dataSource: parseDataSource(json),
      calculation: json['calculation'],
      destinationTable: json['destinationTable'],
      destinationColumn: json['destinationColumn'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['options'] = options.map((e) => e.toJson()).toList();
    if (calculation != null) json['calculation'] = calculation;
    return json;
  }
}
