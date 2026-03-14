import 'package:flutter/foundation.dart';
import '../controller/form_controller.dart';
import '../models/components/select_option.dart';
import '../models/data_source.dart';
import '../utils/error_utils.dart';
import 'datasource_service.dart';

class DatasourceDbService {
  /// Fetches options from a local Database callback.
  static Future<List<SelectOption>> fetchDatabaseOptions({
    required DataSourceDatabase database,
    required FormController controller,
    Map<String, String>? extraParams,
  }) async {
    if (controller.config.onDatabaseQuery == null) return [];

    final query = DatasourceService.interpolateString(
        database.query, controller, extraParams);

    try {
      final data = await controller.config.onDatabaseQuery!(
        database.connectionString,
        database.dbName,
        query,
      );

      return data.map<SelectOption>((item) {
        final rawLabel =
            DatasourceService.extractValue(item, database.labelPath);
        final rawValue =
            DatasourceService.extractValue(item, database.valuePath);

        String finalLabel = '';
        String finalValue = '';

        if (database.labelPath.isEmpty && database.valuePath.isNotEmpty) {
          finalLabel = rawValue?.toString() ?? '';
          finalValue = rawValue?.toString() ?? '';
        } else if (database.valuePath.isEmpty &&
            database.labelPath.isNotEmpty) {
          finalLabel = rawLabel?.toString() ?? '';
          finalValue = rawLabel?.toString() ?? '';
        } else if (database.labelPath.isEmpty && database.valuePath.isEmpty) {
          finalLabel = item.toString();
          finalValue = item.toString();
        } else {
          finalLabel = rawLabel?.toString() ?? '';
          finalValue = rawValue?.toString() ?? '';
        }

        return SelectOption(
          label: finalLabel,
          value: finalValue,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DatasourceDbService Error (fetchDatabaseOptions): ${ErrorUtils.toFriendlyMessage(e)}');
      }
      return [];
    }
  }

  /// Fetches a single default value from a local Database for non-option components.
  static Future<dynamic> fetchDatabaseDefaultValue({
    required DataSourceDatabase database,
    required FormController controller,
  }) async {
    if (controller.config.onDatabaseQuery == null) return null;

    final query =
        DatasourceService.interpolateString(database.query, controller);

    try {
      final data = await controller.config.onDatabaseQuery!(
        database.connectionString,
        database.dbName,
        query,
      );

      if (data.isEmpty) return null;

      // Use the first row for default value
      final firstRow = data.first;

      if (database.valuePath.isNotEmpty) {
        return DatasourceService.extractValue(firstRow, database.valuePath);
      }

      return firstRow.toString();
    } catch (e) {
      if (kDebugMode) print('DatasourceDbService Error (fetchDatabaseDefaultValue): $e');
      return null;
    }
  }
}
