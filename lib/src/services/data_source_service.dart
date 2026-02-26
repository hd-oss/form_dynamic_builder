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
        final keys = api.dataKey.split('.');
        for (final key in keys) {
          if (data is Map<String, dynamic>) {
            data = data[key];
          } else {
            return [];
          }
        }
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

  /// Extracts a value from a nested map using dot-separated path.
  static dynamic _extractValue(dynamic item, String path) {
    if (item == null) return null;
    final parts = path.split('.');
    dynamic current = item;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
