import '../conditional_config.dart';
import 'package:intl/intl.dart';

ConditionalConfig? parseConditional(Map<String, dynamic> json) {
  if (json['conditional'] != null) {
    return ConditionalConfig.fromJson(
        json['conditional'] as Map<String, dynamic>);
  }
  return null;
}

String formatDate(DateTime date, String format) {
  return DateFormat(format).format(date);
}
