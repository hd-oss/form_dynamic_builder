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
