import '../form_component.dart';
import '../validation_rule.dart';
import 'component_utils.dart';

class NumberComponent extends FormComponent {
  final num? min;
  final num? max;
  final bool enableCurrency;
  final String? currency;
  final int? decimalPlaces;

  NumberComponent({
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
    this.min,
    this.max,
    this.enableCurrency = false,
    this.currency,
    this.decimalPlaces,
  });

  factory NumberComponent.fromJson(Map<String, dynamic> json) {
    return NumberComponent(
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
      min: json['min'],
      max: json['max'],
      enableCurrency: json['enableCurrency'] ?? false,
      currency: json['currency'],
      decimalPlaces: json['decimalPlaces'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (min != null) json['min'] = min;
    if (max != null) json['max'] = max;
    json['enableCurrency'] = enableCurrency;
    if (currency != null) json['currency'] = currency;
    if (decimalPlaces != null) json['decimalPlaces'] = decimalPlaces;
    return json;
  }
}
