import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiHandler {
  static Future<dynamic> onApiQuery(
    String url,
    String method,
    Map<String, dynamic> headers,
    dynamic body,
  ) async {
    debugPrint('API Query (Dio): $method $url');
    final dio = Dio();
    try {
      final response = await dio.request(
        url,
        data: body.isNotEmpty ? body : null,
        options: Options(
          method: method,
          headers: headers,
        ),
      );
      return response.data; // Dio parses JSON automatically for maps/lists
    } catch (e) {
      debugPrint('Dio Error: $e');
      return null;
    }
  }

  /// Host-app file upload callback. Returns:
  /// - A `String` URL for simple single-file responses.
  /// - A `Map<String, dynamic>` for object responses.
  /// - A `List<dynamic>` for multiple file results.
  /// - `null` if the upload failed.
  static Future<dynamic> onFileUpload(
    List<String> localPaths,
    String uploadUrl,
  ) async {
    debugPrint('File Upload (Dio): ${localPaths.length} files to $uploadUrl');

    final dio = Dio();
    try {
      final List<dynamic> results = [];

      for (final localPath in localPaths) {
        // MOCK: Simulate failure for specific paths
        if (localPath.contains('fail')) {
          debugPrint('Simulating upload failure for: $localPath');
          continue;
        }

        final fileName = localPath.split(Platform.pathSeparator).last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(localPath, filename: fileName),
        });

        final response = await dio.post(uploadUrl, data: formData);

        if (response.statusCode == 200) {
          // Server returns full object — store as-is
          results.add(response.data);
        }
      }

      if (results.isEmpty && localPaths.isNotEmpty) return null;

      // Return single item directly (not wrapped), or list for multiple
      return results.length == 1 ? results.first : results;
    } catch (e) {
      debugPrint('Dio Upload Error: $e');
      return e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: pretty-print dynamic values for debug
  // ---------------------------------------------------------------------------
  static String prettyPrint(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
