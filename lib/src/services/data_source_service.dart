import 'dart:convert';

import 'package:intl/intl.dart';

import '../controller/form_controller.dart';
import '../models/components/select_option.dart';
import '../models/data_source.dart';

class DataSourceService {
  /// Interpolates placeholders in the URL.
  ///
  /// Supports:
  /// - `{{componentKey}}` — from form field values
  /// - `{{ds_form.task.lcs.xxx}}` / `{{ds_form.task.los.xxx}}` — from dsForm
  /// - `{{var.static.current_year}}` etc — basic date/time variables
  static String interpolateUrl(String url, FormController controller,
      [Map<String, String>? extraParams]) {
    return interpolateString(url, controller, extraParams);
  }

  /// Interpolates placeholders in a string (e.g., URL or Database Query).
  static String interpolateString(String text, FormController controller,
      [Map<String, String>? extraParams]) {
    return text.replaceAllMapped(RegExp(r'\{\{(.+?)\}\}'), (match) {
      final key = match.group(1)!;

      if (extraParams != null && extraParams.containsKey(key)) {
        return Uri.encodeComponent(extraParams[key]!);
      }

      // Basic variables
      if (key.startsWith('var.static.')) {
        return _resolveStaticVar(key.substring('var.static.'.length));
      }

      // DS Form external variables
      if (key.startsWith('ds_form.')) {
        return _resolveDsForm(key.substring('ds_form.'.length), controller);
      }

      // Component value
      final value = controller.getValue(key);
      return value?.toString() ?? '';
    });
  }

  static String _resolveStaticVar(String varName) {
    final now = DateTime.now();
    switch (varName) {
      case 'current_datetime':
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      case 'current_date':
        return DateFormat('yyyy-MM-dd').format(now);
      case 'current_year':
        return now.year.toString();
      case 'current_month':
        return now.month.toString().padLeft(2, '0');
      case 'current_day':
        return now.day.toString().padLeft(2, '0');
      default:
        return '';
    }
  }

  static String _resolveDsForm(String path, FormController controller) {
    final dsForm = controller.dsForm;
    if (dsForm.isEmpty) return '';

    final parts = path.split('.');
    dynamic current = dsForm;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }

  /// Checks if a URL contains `{{componentKey}}` placeholders
  /// (excluding ds_form and var.static).
  static Set<String> extractDependentKeys(String url) {
    final keys = <String>{};
    final matches = RegExp(r'\{\{(.+?)\}\}').allMatches(url);
    for (final match in matches) {
      final key = match.group(1)!;
      if (!key.startsWith('var.static.') &&
          !key.startsWith('ds_form.')) {
        keys.add(key);
      }
    }
    return keys;
  }

  /// Fetches options from a remote API.
  ///
  /// Uses [FormConfig.onApiQuery] to delegate the HTTP request to the host app.
  static Future<List<SelectOption>> fetchOptions({
    required DataSourceApi api,
    required FormController controller,
    Map<String, String>? extraParams,
  }) async {
    if (controller.config.onApiQuery == null) return [];

    final url = interpolateUrl(api.url, controller, extraParams);

    // Build headers
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...controller.authHeaders,
    };
    for (final h in api.headers) {
      headers.addAll(h);
    }

    // Make request via IoC Callback
    dynamic data;
    try {
      final responseData = await controller.config.onApiQuery!(
        url,
        api.method,
        headers,
        api.body,
      );

      data = responseData;
      if (data is String) {
        data = json.decode(data);
      }
    } catch (e) {
      return [];
    }

    // Parse response
    try {
      // Extract nested data using dataKey
      if (api.dataKey.isNotEmpty) {
        data = _extractValue(data, api.dataKey);
        if (data == null) return [];
      }

      if (data is! List) return [];

      return data.map<SelectOption>((item) {
        final rawLabel = _extractValue(item, api.labelPath);
        final rawValue = _extractValue(item, api.valuePath);

        String finalLabel = '';
        String finalValue = '';

        if (api.labelPath.isEmpty && api.valuePath.isNotEmpty) {
          finalLabel = rawValue?.toString() ?? '';
          finalValue = rawValue?.toString() ?? '';
        } else if (api.valuePath.isEmpty && api.labelPath.isNotEmpty) {
          finalLabel = rawLabel?.toString() ?? '';
          finalValue = rawLabel?.toString() ?? '';
        } else if (api.labelPath.isEmpty && api.valuePath.isEmpty) {
          finalLabel = item?.toString() ?? '';
          finalValue = item?.toString() ?? '';
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
      return [];
    }
  }

  /// Fetches options from a local Database callback.
  static Future<List<SelectOption>> fetchDatabaseOptions({
    required DataSourceDatabase database,
    required FormController controller,
    Map<String, String>? extraParams,
  }) async {
    if (controller.config.onDatabaseQuery == null) return [];

    final query = interpolateString(database.query, controller, extraParams);

    try {
      final data = await controller.config.onDatabaseQuery!(
        database.connectionString,
        database.dbName,
        query,
      );

      return data.map<SelectOption>((item) {
        final rawLabel = _extractValue(item, database.labelPath);
        final rawValue = _extractValue(item, database.valuePath);

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
      return [];
    }
  }

  /// Fetches a single default value from a remote API for non-option components.
  ///
  /// Uses [FormConfig.onApiQuery] to delegate the HTTP request to the host app.
  /// Returns `null` on error, non-200 status, or missing path.
  static Future<dynamic> fetchDefaultValue({
    required DataSourceApi api,
    required FormController controller,
  }) async {
    if (controller.config.onApiQuery == null) return null;

    final url = interpolateUrl(api.url, controller);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...controller.authHeaders,
    };
    for (final h in api.headers) {
      headers.addAll(h);
    }

    dynamic data;
    try {
      final responseData = await controller.config.onApiQuery!(
        url,
        api.method,
        headers,
        api.body,
      );

      data = responseData;
      if (data is String) {
        data = json.decode(data);
      }
    } catch (e) {
      return null;
    }

    try {
      // Navigate nested data using dataKey.
      if (api.dataKey.isNotEmpty) {
        data = _extractValue(data, api.dataKey);
        if (data == null) return null;
      }

      // Extract value using valuePath.
      if (api.valuePath.isNotEmpty) {
        return _extractValue(data, api.valuePath);
      }

      // No path — return the whole item's string representation.
      return data?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Fetches a single default value from a local Database for non-option components.
  static Future<dynamic> fetchDatabaseDefaultValue({
    required DataSourceDatabase database,
    required FormController controller,
  }) async {
    if (controller.config.onDatabaseQuery == null) return null;

    final query = interpolateString(database.query, controller);

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
        return _extractValue(firstRow, database.valuePath);
      }

      return firstRow.toString();
    } catch (_) {
      return null;
    }
  }

  /// Extracts a value from a nested map or list using a dot-separated path.
  /// Supports array indexing syntax like `data[0].title` or `[0].title`.
  static dynamic _extractValue(dynamic item, String path) {
    if (item == null || path.isEmpty) return item;

    // Normalize path to use dots for arrays, e.g., "data[0].title" -> "data.0.title"
    // Also handles paths starting with index: "[0].title" -> "0.title"
    final normalizedPath = path.replaceAll('[', '.').replaceAll(']', '');
    final parts = normalizedPath.split('.').where((p) => p.isNotEmpty);

    dynamic current = item;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null; // Index out of bounds or invalid format
        }
      } else {
        // Path asks to dive deeper, but current is not a Map or List
        return null;
      }
    }
    return current;
  }
}
