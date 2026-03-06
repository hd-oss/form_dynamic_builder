import '../form_component.dart';
import '../upload_config.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class FileUploadComponent extends FormComponent {
  final bool multiple;
  final String accept;
  final int maxSize;
  final String uploadUrl;
  final String uploadType;
  final OtherUploadConfig? uploadConfig;
  final bool compressFile;
  final int compressPercentage;
  final String uploadTiming;

  FileUploadComponent({
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
    this.multiple = false,
    this.accept = '',
    this.maxSize = 0,
    this.uploadUrl = '',
    this.uploadType = 'callback',
    this.uploadConfig,
    this.compressFile = false,
    this.compressPercentage = 80,
    this.uploadTiming = 'onSubmit',
  });

  factory FileUploadComponent.fromJson(Map<String, dynamic> json) {
    return FileUploadComponent(
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
      dataSource: parseDataSource(json),
      multiple: json['multiple'] ?? false,
      accept: json['accept'] ?? '',
      maxSize: json['maxSize'] ?? 0,
      uploadUrl: json['uploadUrl'] ?? '',
      uploadType: json['uploadType'] as String? ?? 'callback',
      uploadConfig: json['otherUploadConfig'] != null
          ? OtherUploadConfig.fromJson(
              json['otherUploadConfig'] as Map<String, dynamic>)
          : null,
      compressFile: json['compressFile'] ?? false,
      compressPercentage: json['compressPercentage'] ?? 80,
      uploadTiming: json['uploadTiming'] ?? 'onSubmit',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['multiple'] = multiple;
    json['accept'] = accept;
    json['maxSize'] = maxSize;
    json['uploadUrl'] = uploadUrl;
    json['uploadType'] = uploadType;
    if (uploadConfig != null) {
      json['otherUploadConfig'] = uploadConfig!.toJson();
    }
    json['compressFile'] = compressFile;
    json['compressPercentage'] = compressPercentage;
    json['uploadTiming'] = uploadTiming;
    return json;
  }
}
