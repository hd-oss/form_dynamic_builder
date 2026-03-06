import '../form_component.dart';
import '../upload_config.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class CameraComponent extends FormComponent {
  /// Which camera to open: 'front', 'rear', or 'both' (user can switch).
  final String cameraFacing;

  /// Whether to overlay a timestamp on the captured photo.
  final bool showTimestamp;

  /// Date/time format string for the timestamp overlay, e.g. 'yyyy-MM-dd HH:mm:s'.
  final String timestampFormat;

  /// Whether to overlay GPS coordinates on the captured photo.
  final bool showCoordinates;

  /// Whether to overlay device info (model, OS) on the captured photo.
  final bool showDeviceInfo;

  /// Whether to compress the captured photo before upload/storing.
  final bool compressFile;
  final int compressPercentage;

  /// When to upload: 'immediate' (right after capture) or 'onSubmit'.
  final String uploadTiming;

  /// The URL to upload the captured photo to.
  final String uploadUrl;

  /// Upload type: 'callback' or 'other'.
  final String uploadType;

  /// Config for direct HTTP upload (used when uploadType == 'other').
  final OtherUploadConfig? uploadConfig;

  CameraComponent({
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
    this.cameraFacing = 'both',
    this.showTimestamp = false,
    this.timestampFormat = 'yyyy-MM-dd HH:mm:ss',
    this.showCoordinates = false,
    this.showDeviceInfo = false,
    this.compressFile = false,
    this.compressPercentage = 80,
    this.uploadTiming = 'onSubmit',
    this.uploadUrl = '',
    this.uploadType = 'callback',
    this.uploadConfig,
  });

  factory CameraComponent.fromJson(Map<String, dynamic> json) {
    return CameraComponent(
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
      cameraFacing: json['cameraFacing'] ?? 'both',
      showTimestamp: json['showTimestamp'] ?? false,
      timestampFormat: json['timestampFormat'] ?? 'yyyy-MM-dd HH:mm:ss',
      showCoordinates: json['showCoordinates'] ?? false,
      showDeviceInfo: json['showDeviceInfo'] ?? false,
      compressFile: json['compressFile'] ?? false,
      compressPercentage: json['compressPercentage'] ?? 80,
      uploadTiming: json['uploadTiming'] ?? 'onSubmit',
      uploadUrl: json['uploadUrl'] ?? '',
      uploadType: json['uploadType'] as String? ?? 'callback',
      uploadConfig: json['otherUploadConfig'] != null
          ? OtherUploadConfig.fromJson(
              json['otherUploadConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['cameraFacing'] = cameraFacing;
    json['showTimestamp'] = showTimestamp;
    json['timestampFormat'] = timestampFormat;
    json['showCoordinates'] = showCoordinates;
    json['showDeviceInfo'] = showDeviceInfo;
    json['compressFile'] = compressFile;
    json['compressPercentage'] = compressPercentage;
    json['uploadTiming'] = uploadTiming;
    json['uploadUrl'] = uploadUrl;
    json['uploadType'] = uploadType;
    if (uploadConfig != null) {
      json['otherUploadConfig'] = uploadConfig!.toJson();
    }
    return json;
  }
}
