import '../conditional_config.dart';

ConditionalConfig? parseConditional(Map<String, dynamic> json) {
  if (json['conditional'] != null) {
    return ConditionalConfig.fromJson(
        json['conditional'] as Map<String, dynamic>);
  }
  return null;
}
