import 'dart:io';

import 'package:flutter/foundation.dart';

import '../controller/form_controller.dart';
import '../models/upload_config.dart';
import '../utils/image_compressor.dart';

/// A centralized service to handle file processing (validation, compression)
/// and uploading across all components.
///
/// Under the Inversion of Control (IoC) architecture, this service delegates
/// all upload logic to the host application via [FormConfig.onFileUpload].
class UploadService {
  /// Processes a list of local files and uploads them if required.
  static Future<UploadResult> processAndUpload({
    required List<String> localPaths,
    required FormController formController,
    required String uploadUrl,
    required String uploadTiming,
    String uploadType = 'other',
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

      // 2. Upload Execution (IoC via Host App)
      if (uploadTiming == 'immediate' && uploadUrl.isNotEmpty) {
        if (formController.config.onFileUpload != null) {
          // Pass local paths, upload URL, and optional uploadConfig (if type is 'other')
          final result = await formController.config.onFileUpload!(
            processedPaths,
            uploadUrl,
            uploadType == 'other' ? uploadConfig : null,
          );

          if (result != null) {
            // Normalize result: String → [String], List → as-is, Map → [Map]
            final List<dynamic> values = result is List ? result : [result];
            return UploadResult.success(values, wasUploaded: true);
          } else {
            return UploadResult.error(
              'Upload failed. Saved locally.',
              localPaths: processedPaths,
            );
          }
        }
      }

      // Manual upload or no callback provided: return processed local paths
      return UploadResult.success(processedPaths, wasUploaded: false);
    } catch (e) {
      if (kDebugMode) print('UploadService Error: $e');
      return UploadResult.error('Processing failed: $e');
    }
  }

  static bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }
}

class UploadResult {
  final bool isSuccess;
  final bool wasUploaded;
  final List<dynamic> values;
  final String? errorMessage;
  final List<String>? localPaths;

  UploadResult({
    required this.isSuccess,
    required this.values,
    this.wasUploaded = false,
    this.errorMessage,
    this.localPaths,
  });

  factory UploadResult.success(List<dynamic> values,
          {bool wasUploaded = false}) =>
      UploadResult(
        isSuccess: true,
        values: values,
        wasUploaded: wasUploaded,
      );

  factory UploadResult.error(String message, {List<String>? localPaths}) =>
      UploadResult(
        isSuccess: false,
        values: [],
        errorMessage: message,
        localPaths: localPaths,
      );
}
