import '../form_component.dart';

class ButtonComponent extends FormComponent {
  final String action;
  final String theme;

  ButtonComponent({
    required super.id,
    required super.type,
    required super.key,
    required super.label,
    super.placeholder,
    super.required,
    super.disabled,
    super.hidden,
    this.action = 'submit',
    this.theme = 'primary',
  });

  factory ButtonComponent.fromJson(Map<String, dynamic> json) {
    return ButtonComponent(
      id: json['id'],
      type: json['type'],
      key: json['key'],
      label: json['label'],
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      disabled: json['disabled'] ?? false,
      hidden: json['hidden'] ?? false,
      action: json['action'] ?? 'submit',
      theme: json['theme'] ?? 'primary',
    );
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['action'] = action;
    json['theme'] = theme;
    return json;
  }
}
