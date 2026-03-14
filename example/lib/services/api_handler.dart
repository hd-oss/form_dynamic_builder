import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

class ApiHandler {
  static Future<dynamic> onApiQuery(
    String url,
    String method,
    Map<String, dynamic> headers,
    dynamic body,
  ) async {
    debugPrint('API Query (Dio): $method $url');
    final dio = Dio();
    return await dio.request(
      url,
      data: body.isNotEmpty ? body : null,
      options: Options(
        method: method,
        headers: headers,
      ),
    );
  }

  /// Host-app file upload callback. Returns:
  /// - A `String` URL for simple single-file responses.
  /// - A `Map<String, dynamic>` for object responses.
  /// - A `List<dynamic>` for multiple file results.
  /// - `null` if the upload failed.
  static Future<dynamic> onFileUpload(
    List<String> localPaths,
    String uploadUrl,
    OtherUploadConfig? uploadConfig,
  ) async {
    debugPrint('File Upload (Dio): ${localPaths.length} files to $uploadUrl');

    final dio = Dio();
    final List<dynamic> results = [];

    // Parse OtherUploadConfig if provided
    Map<String, String> extraHeaders = {
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    Map<String, dynamic> extraBody = {};

    if (uploadConfig != null) {
      for (final header in uploadConfig.headers) {
        extraHeaders[header.key] = header.value;
      }
      for (final field in uploadConfig.extraBodyFields) {
        extraBody[field.key] = field.value;
      }
    }

    for (final localPath in localPaths) {
      final fileName = localPath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        ...extraBody,
        '${uploadConfig?.fileFieldName}': await MultipartFile.fromFile(
          localPath,
          filename: fileName,
        ),
      });

      final response = await dio.request(
        uploadUrl,
        data: formData,
        options: Options(
          method: uploadConfig?.method,
          headers: extraHeaders.isNotEmpty ? extraHeaders : null,
        ),
      );

      results.add(response);
    }

    if (results.isEmpty && localPaths.isNotEmpty) return null;

    // Return single item directly (not wrapped), or list for multiple
    return results.length == 1 ? results.first : results;
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
