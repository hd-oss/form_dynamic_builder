import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../controller/form_controller.dart';
import '../models/upload_config.dart';
import '../utils/image_compressor.dart';

/// A centralized service to handle file processing (validation, compression)
/// and uploading across all components.
///
/// Supports two upload strategies:
/// - **callback**: delegates to [FormConfig.onFileUpload] (host-app controlled).
/// - **other**: performs a direct multipart HTTP request using [OtherUploadConfig].
class UploadService {
  /// Processes a list of local files and uploads them if required.
  static Future<UploadResult> processAndUpload({
    required List<String> localPaths,
    required FormController formController,
    required String uploadUrl,
    required String uploadTiming,
    String uploadType = 'callback',
    OtherUploadConfig? uploadConfig,
    bool compressFile = false,
    int compressPercentage = 80,
    int maxSize = 0,
  }) async {
    try {
      final List<String> processedPaths = [];

      // 1. Validation & Compression
      for (final path in localPaths) {
        final file = File(path);
        if (!file.existsSync()) continue;

        // Size validation
        if (maxSize > 0 && file.lengthSync() > maxSize) {
          final fileName = path.split(Platform.pathSeparator).last;
          return UploadResult.error('$fileName exceeds max size limit.');
        }

        // Compression
        String pathToUpload = path;
        if (compressFile && _isImage(path)) {
          pathToUpload = await ImageCompressor.compressImage(
            imagePath: path,
            quality: compressPercentage,
          );
        }
        processedPaths.add(pathToUpload);
      }

      if (processedPaths.isEmpty) {
        return UploadResult.success([]);
      }

      // 2. Upload Execution
      if (uploadTiming == 'immediate' && uploadUrl.isNotEmpty) {
        // Strategy A: Direct HTTP upload via OtherUploadConfig
        if (uploadType == 'other' && uploadConfig != null) {
          return await _uploadDirect(
            paths: processedPaths,
            uploadUrl: uploadUrl,
            config: uploadConfig,
            formController: formController,
          );
        }

        // Strategy B: Delegate to host-app callback
        if (formController.config.onFileUpload != null) {
          final result = await formController.config.onFileUpload!(
            processedPaths,
            uploadUrl,
          );

          if (result != null) {
            // Normalize result: String → [String], List → as-is, Map → [Map]
            final List<dynamic> values = result is List ? result : [result];
            return UploadResult.success(values);
          } else {
            return UploadResult.error(
              'Upload failed. Saved locally.',
              localPaths: processedPaths,
            );
          }
        }
      }

      // Manual upload or no callback/config: return processed local paths
      return UploadResult.success(processedPaths);
    } catch (e) {
      if (kDebugMode) print('UploadService Error: $e');
      return UploadResult.error('Processing failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Direct HTTP Upload (uploadType == 'other')
  // ---------------------------------------------------------------------------

  static Future<UploadResult> _uploadDirect({
    required List<String> paths,
    required String uploadUrl,
    required OtherUploadConfig config,
    required FormController formController,
  }) async {
    // Single file → individual request
    // Multiple files selected at once → one batch multipart request
    if (paths.length == 1) {
      return _uploadSingle(
        path: paths.first,
        uploadUrl: uploadUrl,
        config: config,
        formController: formController,
      );
    } else {
      return _uploadBatch(
        paths: paths,
        uploadUrl: uploadUrl,
        config: config,
        formController: formController,
      );
    }
  }

  /// Single file: one HTTP request, one response.
  static Future<UploadResult> _uploadSingle({
    required String path,
    required String uploadUrl,
    required OtherUploadConfig config,
    required FormController formController,
  }) async {
    try {
      final url = Uri.parse(_resolveTemplate(uploadUrl, formController));
      final client = HttpClient();
      final request = await _createRequest(client, config.method, url);

      final resolvedHeaders = _resolveKeyValues(config.headers, formController);
      for (final entry in resolvedHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }

      final boundary =
          '----FormDynBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );

      final body = await _buildMultipartBody(
        boundary: boundary,
        filePaths: [path],
        extraFields: _resolveKeyValues(config.extraBodyFields, formController),
        fileFieldName: config.fileFieldName,
      );
      request.contentLength = body.length;
      request.add(body);

      final response = await request.close();
      final responseBody = await response.transform(const Utf8Decoder()).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final extracted =
            _extractValueFromResponse(responseBody, config.responseFileUrlPath);
        if (extracted != null) {
          return UploadResult.success([extracted]);
        }
        return UploadResult.error(
            'Upload succeeded but could not extract value from response.');
      }
      return UploadResult.error(
          'Upload failed with status ${response.statusCode}: $responseBody');
    } catch (e) {
      if (kDebugMode) print('UploadService._uploadSingle Error: $e');
      return UploadResult.error('Upload failed: $e');
    }
  }

  /// Batch: all files in ONE multipart request.
  /// Response is expected to be an array or object.
  static Future<UploadResult> _uploadBatch({
    required List<String> paths,
    required String uploadUrl,
    required OtherUploadConfig config,
    required FormController formController,
  }) async {
    try {
      final url = Uri.parse(_resolveTemplate(uploadUrl, formController));
      final client = HttpClient();
      final request = await _createRequest(client, config.method, url);

      final resolvedHeaders = _resolveKeyValues(config.headers, formController);
      for (final entry in resolvedHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }

      final boundary =
          '----FormDynBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );

      final body = await _buildMultipartBody(
        boundary: boundary,
        filePaths: paths,
        extraFields: _resolveKeyValues(config.extraBodyFields, formController),
        fileFieldName: config.fileFieldName,
      );
      request.contentLength = body.length;
      request.add(body);

      final response = await request.close();
      final responseBody = await response.transform(const Utf8Decoder()).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final extracted =
            _extractValueFromResponse(responseBody, config.responseFileUrlPath);
        if (extracted == null) {
          return UploadResult.error(
              'Batch upload succeeded but could not extract value from response.');
        }
        // If server returns a List, spread it; otherwise wrap in list
        final List<dynamic> values =
            extracted is List ? extracted : [extracted];
        return UploadResult.success(values);
      }
      return UploadResult.error(
          'Batch upload failed with status ${response.statusCode}: $responseBody');
    } catch (e) {
      if (kDebugMode) print('UploadService._uploadBatch Error: $e');
      return UploadResult.error('Batch upload failed: $e');
    }
  }

  /// Creates an [HttpClientRequest] for the given method and URL.
  static Future<HttpClientRequest> _createRequest(
      HttpClient client, String method, Uri url) {
    switch (method.toUpperCase()) {
      case 'PUT':
        return client.putUrl(url);
      case 'PATCH':
        return client.patchUrl(url);
      case 'POST':
      default:
        return client.postUrl(url);
    }
  }

  /// Builds a multipart/form-data body as bytes.
  static Future<List<int>> _buildMultipartBody({
    required String boundary,
    required List<String> filePaths,
    required Map<String, String> extraFields,
    String fileFieldName = 'file',
  }) async {
    final bytes = <int>[];

    // Extra body fields first
    for (final entry in extraFields.entries) {
      bytes.addAll(utf8.encode('--$boundary\r\n'));
      bytes.addAll(utf8.encode(
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n'));
      bytes.addAll(utf8.encode('${entry.value}\r\n'));
    }

    // File parts — single file: name=fileFieldName
    //               multiple files: name=fileFieldName[] (repeated)
    final multiFile = filePaths.length > 1;
    for (final filePath in filePaths) {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final fieldName = multiFile ? '$fileFieldName[]' : fileFieldName;
      bytes.addAll(utf8.encode('--$boundary\r\n'));
      bytes.addAll(utf8.encode(
          'Content-Disposition: form-data; name="$fieldName"; filename="$fileName"\r\n'));
      bytes.addAll(utf8.encode('Content-Type: ${_mimeType(fileName)}\r\n\r\n'));
      bytes.addAll(await File(filePath).readAsBytes());
      bytes.addAll(utf8.encode('\r\n'));
    }

    // Closing boundary
    bytes.addAll(utf8.encode('--$boundary--\r\n'));
    return bytes;
  }

  // ---------------------------------------------------------------------------
  // Template / Response Helpers
  // ---------------------------------------------------------------------------

  /// Resolves `{{ key }}` placeholders in [template] from form values.
  static String _resolveTemplate(String template, FormController controller) {
    return template.replaceAllMapped(
      RegExp(r'\{\{\s*(\w+)\s*\}\}'),
      (match) {
        final key = match.group(1)!;
        final value = controller.getValue(key);
        return value?.toString() ?? match.group(0)!;
      },
    );
  }

  /// Resolves all values in a list of [UploadKeyValue] using template resolution.
  static Map<String, String> _resolveKeyValues(
      List<UploadKeyValue> entries, FormController controller) {
    return {
      for (final e in entries) e.key: _resolveTemplate(e.value, controller),
    };
  }

  /// Extracts a value from a JSON response body using a dot-notation [path].
  ///
  /// Behavior:
  /// - If [path] is empty → returns the entire parsed response (`Map`, `List`, or `String`).
  /// - If [path] resolves to an object/list → returns that object/list as-is.
  /// - If [path] resolves to a primitive → returns it as a `String`.
  static dynamic _extractValueFromResponse(String responseBody, String path) {
    dynamic decoded;
    try {
      decoded = jsonDecode(responseBody);
    } catch (_) {
      // Response is not JSON, return raw string
      return responseBody.trim().isNotEmpty ? responseBody.trim() : null;
    }

    if (path.isEmpty) {
      // Return entire parsed response
      return decoded;
    }

    for (final segment in path.split('.')) {
      if (decoded is Map<String, dynamic>) {
        decoded = decoded[segment];
      } else {
        return null; // Path not found
      }
    }

    return decoded; // Could be String, Map, List, num, bool, or null
  }

  static bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  static String _mimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}

class UploadResult {
  final bool isSuccess;

  /// The resolved values from the upload response.
  /// Each entry can be:
  /// - A `String` (URL or raw value)
  /// - A `Map<String, dynamic>` (server-returned object)
  /// - Any other `dynamic` type from the server response
  final List<dynamic> values;
  final String? errorMessage;
  final List<String>? localPaths;

  UploadResult({
    required this.isSuccess,
    required this.values,
    this.errorMessage,
    this.localPaths,
  });

  factory UploadResult.success(List<dynamic> values) => UploadResult(
        isSuccess: true,
        values: values,
      );

  factory UploadResult.error(String message, {List<String>? localPaths}) =>
      UploadResult(
        isSuccess: false,
        values: [],
        errorMessage: message,
        localPaths: localPaths,
      );
}
