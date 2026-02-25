import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class LocationComponent extends FormComponent {
  /// If true, shows an interactive map picker (flutter_map + OpenStreetMap).
  /// If false, only shows a "Detect Location" GPS button.
  final bool enableMapPicker;

  LocationComponent({
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
    this.enableMapPicker = false,
  });

  factory LocationComponent.fromJson(Map<String, dynamic> json) {
    return LocationComponent(
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
      enableMapPicker: json['enableMapPicker'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['enableMapPicker'] = enableMapPicker;
    return json;
  }
}
