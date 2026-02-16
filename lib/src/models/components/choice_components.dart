import '../form_component.dart';

class CheckboxComponent extends FormComponent {
  final bool defaultValue;

  CheckboxComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.defaultValue = false,
  });

  factory CheckboxComponent.fromJson(Map<String, dynamic> json) {
    return CheckboxComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      defaultValue: json['defaultValue'] ?? false,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['defaultValue'] = defaultValue;
    return json;
  }
}

class SelectOption {
  final String label;
  final String value;

  SelectOption({required this.label, required this.value});

  factory SelectOption.fromJson(Map<String, dynamic> json) {
    return SelectOption(
      label: json['label'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

class SelectComponent extends FormComponent {
  final List<SelectOption> options;

  SelectComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.options = const [],
  });

  factory SelectComponent.fromJson(Map<String, dynamic> json) {
    var optionsList = <SelectOption>[];
    if (json['options'] != null) {
      optionsList = (json['options'] as List)
          .map((e) => SelectOption.fromJson(e))
          .toList();
    }
    return SelectComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      options: optionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['options'] = options.map((e) => e.toJson()).toList();
    return json;
  }
}

class RadioComponent extends FormComponent {
  final List<SelectOption> options;

  RadioComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.options = const [],
  });

  factory RadioComponent.fromJson(Map<String, dynamic> json) {
    var optionsList = <SelectOption>[];
    if (json['options'] != null) {
      optionsList = (json['options'] as List)
          .map((e) => SelectOption.fromJson(e))
          .toList();
    }
    return RadioComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      options: optionsList,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['options'] = options.map((e) => e.toJson()).toList();
    return json;
  }
}
