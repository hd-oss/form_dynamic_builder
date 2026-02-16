import '../form_component.dart';

class TextFieldComponent extends FormComponent {
  TextFieldComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
  });

  factory TextFieldComponent.fromJson(Map<String, dynamic> json) {
    return TextFieldComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
    );
  }
}

class TextAreaComponent extends FormComponent {
  final int rows;

  TextAreaComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.rows = 3,
  });

  factory TextAreaComponent.fromJson(Map<String, dynamic> json) {
    return TextAreaComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      rows: json['rows'] ?? 3,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['rows'] = rows;
    return json;
  }
}

class NumberComponent extends FormComponent {
  NumberComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
  });

  factory NumberComponent.fromJson(Map<String, dynamic> json) {
    return NumberComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
    );
  }
}

class PasswordComponent extends FormComponent {
  final bool showToggle;

  PasswordComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.showToggle = true,
  });

  factory PasswordComponent.fromJson(Map<String, dynamic> json) {
    return PasswordComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      showToggle: json['showToggle'] ?? true,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['showToggle'] = showToggle;
    return json;
  }
}

class DateTimeComponent extends FormComponent {
  final bool enableTime;

  DateTimeComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.enableTime = false,
  });

  factory DateTimeComponent.fromJson(Map<String, dynamic> json) {
    return DateTimeComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      enableTime: json['enableTime'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['enableTime'] = enableTime;
    return json;
  }
}

class CurrencyComponent extends FormComponent {
  final String currency;
  final int decimalPlaces;

  CurrencyComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.currency = 'IDR',
    this.decimalPlaces = 2,
  });

  factory CurrencyComponent.fromJson(Map<String, dynamic> json) {
    return CurrencyComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      currency: json['currency'] ?? 'IDR',
      decimalPlaces: json['decimalPlaces'] ?? 2,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['currency'] = currency;
    json['decimalPlaces'] = decimalPlaces;
    return json;
  }
}

class FileComponent extends FormComponent {
  final bool multiple;

  FileComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.multiple = false,
  });

  factory FileComponent.fromJson(Map<String, dynamic> json) {
    return FileComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      multiple: json['multiple'] ?? false,
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['multiple'] = multiple;
    return json;
  }
}

class SignatureComponent extends FormComponent {
  final double? width;
  final double? height;

  SignatureComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.width,
    this.height,
  });

  factory SignatureComponent.fromJson(Map<String, dynamic> json) {
    return SignatureComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    return json;
  }
}
