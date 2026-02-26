import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class DateTimeComponent extends FormComponent {
  final bool enableTime;
  final bool timeOnly;
  final int? timeHourStep;
  final int? timeMinuteStep;
  final bool timeUse24Hour;
  final Map<String, dynamic>? setBefore;
  final Map<String, dynamic>? setAfter;
  final String? format;

  DateTimeComponent({
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
    this.enableTime = false,
    this.timeOnly = false,
    this.timeHourStep,
    this.timeMinuteStep,
    this.timeUse24Hour = false,
    this.setBefore,
    this.setAfter,
    this.format,
  });

  factory DateTimeComponent.fromJson(Map<String, dynamic> json) {
    return DateTimeComponent(
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
      enableTime: json['enableTime'] ?? false,
      timeOnly: json['timeOnly'] ?? false,
      timeHourStep: json['timeHourStep'],
      timeMinuteStep: json['timeMinuteStep'],
      timeUse24Hour: json['timeUse24Hour'] ?? false,
      setBefore: json['setBefore'],
      setAfter: json['setAfter'],
      format: json['format'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['enableTime'] = enableTime;
    json['timeOnly'] = timeOnly;
    if (timeHourStep != null) json['timeHourStep'] = timeHourStep;
    if (timeMinuteStep != null) json['timeMinuteStep'] = timeMinuteStep;
    json['timeUse24Hour'] = timeUse24Hour;
    if (setBefore != null) json['setBefore'] = setBefore;
    if (setAfter != null) json['setAfter'] = setAfter;
    if (format != null) json['format'] = format;
    return json;
  }
}
