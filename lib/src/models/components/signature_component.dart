import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class SignatureComponent extends FormComponent {
  final double? width;
  final double? height;
  final String uploadUrl;
  final String uploadTiming;

  SignatureComponent({
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
    this.width,
    this.height,
    this.uploadUrl = '',
    this.uploadTiming = 'onSubmit',
  });

  factory SignatureComponent.fromJson(Map<String, dynamic> json) {
    return SignatureComponent(
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
      dataSource: parseDataSource(json),
      defaultValue: json['defaultValue'],
      platforms: json['platforms'],
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      uploadUrl: json['uploadUrl'] ?? '',
      uploadTiming: json['uploadTiming'] ?? 'onSubmit',
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    json['uploadUrl'] = uploadUrl;
    json['uploadTiming'] = uploadTiming;
    return json;
  }
}
