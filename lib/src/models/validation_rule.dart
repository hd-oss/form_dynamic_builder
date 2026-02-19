import '../utils/form_constants.dart';

class ValidationRule {
  final String type;
  final dynamic value;
  final String message;

  ValidationRule({
    required this.type,
    this.value,
    required this.message,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      type: json['type'] as String,
      value: json['value'],
      message: json['message'] as String? ?? FormConstants.defaultMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (value != null) 'value': value,
      'message': message,
    };
  }
}
