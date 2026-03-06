import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class PanelComponent extends FormComponent {
  final List<FormComponent> components;
  final String theme;

  PanelComponent({
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
    this.components = const [],
    this.theme = 'default',
  });

  factory PanelComponent.fromJson(Map<String, dynamic> json) {
    return PanelComponent(
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
      dataSource: parseDataSource(json),
      destinationTable: json['destinationTable'],
      destinationColumn: json['destinationColumn'],
      components: (json['components'] as List?)
              ?.map((e) => FormComponent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      theme: json['theme'] ?? 'default',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['components'] = components.map((e) => e.toJson()).toList();
    json['theme'] = theme;
    return json;
  }
}
