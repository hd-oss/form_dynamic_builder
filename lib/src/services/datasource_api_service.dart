import 'dart:convert';
import '../controller/form_controller.dart';
import '../models/components/select_option.dart';
import '../models/data_source.dart';
import 'datasource_service.dart'; // For shared interpolation/extraction methods.

class DatasourceApiService {
  /// Fetches options from a remote API.
  ///
  /// Uses [FormConfig.onApiQuery] to delegate the HTTP request to the host app.
  static Future<List<SelectOption>> fetchOptions({
    required DataSourceApi api,
    required FormController controller,
    Map<String, String>? extraParams,
  }) async {
    if (controller.config.onApiQuery == null) return [];

    final url =
        DatasourceService.interpolateUrl(api.url, controller, extraParams);

    // Build headers
    final headers = <String, String>{};
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
        data = DatasourceService.extractValue(data, api.dataKey);
        if (data == null) return [];
      }

      if (data is! List) return [];

      return data.map<SelectOption>((item) {
        final rawLabel = DatasourceService.extractValue(item, api.labelPath);
        final rawValue = DatasourceService.extractValue(item, api.valuePath);

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

  /// Fetches a single default value from a remote API for non-option components.
  ///
  /// Uses [FormConfig.onApiQuery] to delegate the HTTP request to the host app.
  /// Returns `null` on error, non-200 status, or missing path.
  static Future<dynamic> fetchDefaultValue({
    required DataSourceApi api,
    required FormController controller,
  }) async {
    if (controller.config.onApiQuery == null) return null;

    final url = DatasourceService.interpolateUrl(api.url, controller);

    final headers = <String, String>{};
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
        data = DatasourceService.extractValue(data, api.dataKey);
        if (data == null) return null;
      }

      // Extract value using valuePath.
      if (api.valuePath.isNotEmpty) {
        return DatasourceService.extractValue(data, api.valuePath);
      }

      // No path — return the whole item's string representation.
      return data?.toString();
    } catch (_) {
      return null;
    }
  }
}
