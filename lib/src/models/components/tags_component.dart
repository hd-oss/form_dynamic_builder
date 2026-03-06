import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class TagsComponent extends FormComponent {
  final String? placeholderTags;
  final String storeAs;
  final int? maxTags;

  TagsComponent({
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
    this.storeAs = 'string',
    this.placeholderTags,
    this.maxTags,
  });

  factory TagsComponent.fromJson(Map<String, dynamic> json) {
    return TagsComponent(
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
      storeAs: json['storeAs'] ?? 'string',
      placeholderTags: json['placeholderTags'],
      maxTags: json['maxTags'],
      dataSource: parseDataSource(json),
      destinationTable: json['destinationTable'],
      destinationColumn: json['destinationColumn'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['storeAs'] = storeAs;
    if (placeholderTags != null) json['placeholderTags'] = placeholderTags;
    if (maxTags != null) json['maxTags'] = maxTags;
    return json;
  }
}
