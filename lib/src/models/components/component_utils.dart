import 'package:intl/intl.dart';

import '../conditional_config.dart';
import '../data_source.dart';

ConditionalConfig? parseConditional(Map<String, dynamic> json) {
  if (json['conditional'] != null) {
    return ConditionalConfig.fromJson(
        json['conditional'] as Map<String, dynamic>);
  }
  return null;
}

DataSource? parseDataSource(Map<String, dynamic> json) {
  final platforms = json['platforms'] as Map<String, dynamic>?;
  if (platforms != null && platforms.containsKey('mobile')) {
    final mobile = platforms['mobile'] as Map<String, dynamic>?;
    if (mobile != null && mobile['dataSource'] != null) {
      return DataSource.fromJson(mobile['dataSource'] as Map<String, dynamic>);
    }
  }

  if (json['dataSource'] != null) {
    return DataSource.fromJson(json['dataSource'] as Map<String, dynamic>);
  }
  return null;
}

String formatDate(DateTime date, String format) {
  return DateFormat(format).format(date);
}
