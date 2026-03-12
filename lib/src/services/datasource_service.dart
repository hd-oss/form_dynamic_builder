import 'package:intl/intl.dart';

import '../controller/form_controller.dart';

class DatasourceService {
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
      final key = match.group(1)!.trim();

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
      final key = match.group(1)!.trim();
      if (!key.startsWith('var.static.') && !key.startsWith('ds_form.')) {
        keys.add(key);
      }
    }
    return keys;
  }

  /// Extracts a value from a nested map or list using a dot-separated path.
  /// Supports array indexing syntax like `data[0].title` or `[0].title`.
  static dynamic extractValue(dynamic item, String path) {
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
