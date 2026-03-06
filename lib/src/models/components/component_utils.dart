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

/// Returns the shared destination fields parsed from [json].
/// Spread this result into sub-component constructors:
/// ```dart
/// ...parseDestination(json),
/// ```
Map<String, dynamic> parseDestination(Map<String, dynamic> json) {
  return {
    if (json['destinationTable'] != null)
      'destinationTable': json['destinationTable'] as String,
    if (json['destinationColumn'] != null)
      'destinationColumn': json['destinationColumn'] as String,
  };
}

String formatDate(DateTime date, String format) {
  return DateFormat(format).format(date);
}
