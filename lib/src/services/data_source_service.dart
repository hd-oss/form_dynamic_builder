import 'dart:convert';

import 'package:http/http.dart' as http;
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
  static String interpolateUrl(String url, FormController controller) {
    return url.replaceAllMapped(RegExp(r'\{\{(.+?)\}\}'), (match) {
      final key = match.group(1)!;

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
    final dsForm = controller.config.dsForm;
    if (dsForm == null) return '';

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
      if (!key.startsWith('var.static.') && !key.startsWith('ds_form.')) {
        keys.add(key);
      }
    }
    return keys;
  }

  /// Fetches options from a remote API.
  ///
  /// Pass [httpClient] to inject a mock client in tests.
  /// When null, a new [http.Client] is created per request.
  static Future<List<SelectOption>> fetchOptions({
    required DataSourceApi api,
    required FormController controller,
    http.Client? httpClient,
  }) async {
    final url = interpolateUrl(api.url, controller);

    // Build headers
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...controller.authHeaders,
    };
    for (final h in api.headers) {
      headers.addAll(h);
    }

    // Make request
    final client = httpClient ?? http.Client();
    http.Response response;
    try {
      final uri = Uri.parse(url);
      if (api.method.toUpperCase() == 'POST') {
        response = await client.post(
          uri,
          headers: headers,
          body: api.body.isNotEmpty ? api.body : null,
        );
      } else {
        response = await client.get(uri, headers: headers);
      }
    } catch (e) {
      return [];
    } finally {
      // Only close client that we created ourselves.
      if (httpClient == null) client.close();
    }

    if (response.statusCode != 200) return [];

    // Parse response
    try {
      dynamic data = json.decode(response.body);

      // Extract nested data using dataKey
      if (api.dataKey.isNotEmpty) {
        data = _extractValue(data, api.dataKey);
        if (data == null) return [];
      }

      if (data is! List) return [];

      return data.map<SelectOption>((item) {
        final label = _extractValue(item, api.labelPath);
        final value = _extractValue(item, api.valuePath);
        return SelectOption(
          label: label?.toString() ?? '',
          value: value?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches a single default value from a remote API for non-option components.
  ///
  /// Uses [DataSourceApi.valuePath] to extract the value from the response.
  /// If the response root is a **List**, the first item is used.
  /// If the response root is a **Map** (object), it is used directly.
  ///
  /// Returns `null` on error, non-200 status, or missing path.
  static Future<dynamic> fetchDefaultValue({
    required DataSourceApi api,
    required FormController controller,
    http.Client? httpClient,
  }) async {
    final url = interpolateUrl(api.url, controller);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...controller.authHeaders,
    };
    for (final h in api.headers) {
      headers.addAll(h);
    }

    final client = httpClient ?? http.Client();
    http.Response response;
    try {
      final uri = Uri.parse(url);
      if (api.method.toUpperCase() == 'POST') {
        response = await client.post(
          uri,
          headers: headers,
          body: api.body.isNotEmpty ? api.body : null,
        );
      } else {
        response = await client.get(uri, headers: headers);
      }
    } catch (e) {
      return null;
    } finally {
      if (httpClient == null) client.close();
    }

    if (response.statusCode != 200) return null;

    try {
      dynamic data = json.decode(response.body);

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
