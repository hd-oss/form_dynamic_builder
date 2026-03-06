import '../data_source.dart';

class DateLimitConfig {
  final String type; // 'static', 'api', 'database'
  final int? value;
  final String? unit; // 'days', 'months', 'years'
  final DataSourceApi? api;
  final DataSourceDatabase? database;

  DateLimitConfig({
    required this.type,
    this.value,
    this.unit,
    this.api,
    this.database,
  });

  factory DateLimitConfig.fromJson(Map<String, dynamic> json) {
    return DateLimitConfig(
      type: json['type'] ?? 'static',
      value: json['value'] as int?,
      unit: json['unit'] as String?,
      api: json['api'] != null
          ? DataSourceApi.fromJson(json['api'] as Map<String, dynamic>)
          : null,
      database: json['database'] != null
          ? DataSourceDatabase.fromJson(
              json['database'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (api != null) 'api': api!.toJson(),
      if (database != null) 'database': database!.toJson(),
    };
  }

  bool get isApi => type == 'api' && api != null;
  bool get isDatabase => type == 'database' && database != null;
  bool get isDynamic => isApi || isDatabase;
}
