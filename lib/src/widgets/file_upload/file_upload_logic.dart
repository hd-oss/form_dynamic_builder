import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/file_data.dart';
import '../../services/mixins/upload_mixin.dart';
import '../../services/upload_service.dart';

class FileUploadLogic extends ChangeNotifier with UploadMixin {
  final FileUploadComponent component;
  final FormController formController;

  final List<String> _uploadingFiles = [];
  List<String> get uploadingFiles => List.unmodifiable(_uploadingFiles);

  FileUploadLogic(this.component, this.formController);

  String formatMaxSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String buildHelperText() {
    final parts = <String>[];
    if (component.accept.isNotEmpty) {
      parts.add('Accepted: ${component.accept.toUpperCase()}');
    }
    if (component.maxSize > 0) {
      parts.add('Max: ${formatMaxSize(component.maxSize)}');
    }
    if (component.multiple) {
      parts.add('Multiple files allowed');
    }
    if (component.compressFile) {
      parts.add('Compress: ${component.compressPercentage}%');
    }
    return parts.join(' · ');
  }

  Future<String?> pickFiles(List<dynamic> current) async {
    try {
      List<String>? extensions;
      FileType fileType = FileType.any;

      if (component.accept.isNotEmpty) {
        extensions = component.accept
            .split(',')
            .map((e) => e.trim().toLowerCase().replaceAll('.', ''))
            .where((e) => e.isNotEmpty)
            .toList();
        if (extensions.isNotEmpty) {
          fileType = FileType.custom;
        } else {
          extensions = null;
        }
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: component.multiple,
        type: fileType,
        allowedExtensions: extensions,
      );

      if (result != null) {
        final List<String> selectedLocalPaths = result.files
            .where((f) => f.path != null)
            .map((f) => f.path!)
            .toList();

        if (selectedLocalPaths.isEmpty) return null;

        // Start Upload Task
        _uploadingFiles.addAll(selectedLocalPaths);
        updateUploadStatus(UploadStatus.uploading);
        notifyListeners();

        final uploadResult = await UploadService.processAndUpload(
          localPaths: selectedLocalPaths,
          formController: formController,
          uploadUrl: component.uploadUrl,
          uploadTiming: component.uploadTiming,
          uploadType: component.uploadType,
          uploadConfig: component.uploadConfig,
          compressFile: component.compressFile,
          compressPercentage: component.compressPercentage,
          maxSize: component.maxSize,
        );

        // Remove from uploading list
        _uploadingFiles.removeWhere((p) => selectedLocalPaths.contains(p));

        if (uploadResult.isSuccess) {
          // Build FileData objects — name always comes from local selection
          final newEntries = <FileData>[];
          final values = uploadResult.values;
          for (int i = 0; i < selectedLocalPaths.length; i++) {
            final localPath = selectedLocalPaths[i];
            final size = File(localPath).existsSync()
                ? File(localPath).lengthSync()
                : null;
            // Match upload result value to this file (values may be fewer if batch)
            final resultValue = i < values.length ? values[i] : null;
            final fileData = FileData.fromUpload(
              localPath: localPath,
              size: size,
              uploadedUrl: resultValue is String ? resultValue : null,
              uploadResponse: resultValue is! String ? resultValue : null,
            );
            newEntries.add(fileData);
          }

          if (component.multiple) {
            final merged = List<FileData>.from(
              current.whereType<FileData>(),
            )..addAll(newEntries);
            formController.updateValue(component.key, merged);
          } else {
            formController.updateValue(component.key, newEntries.first);
          }
          updateUploadStatus(UploadStatus.success);
        } else {
          // Failure: keep local file as-is with status 'local'
          final fallbackPaths = uploadResult.localPaths ?? selectedLocalPaths;
          final newEntries = fallbackPaths.map((p) {
            final size = File(p).existsSync() ? File(p).lengthSync() : null;
            return FileData.fromLocalPath(p, size: size);
          }).toList();

          if (component.multiple) {
            final merged = List<FileData>.from(
              current.whereType<FileData>(),
            )..addAll(newEntries);
            formController.updateValue(component.key, merged);
          } else {
            formController.updateValue(component.key, newEntries.first);
          }
          updateUploadStatus(UploadStatus.error,
              error: uploadResult.errorMessage);
          return uploadResult.errorMessage;
        }
      } else {
        updateUploadStatus(UploadStatus.idle);
      }
      return null;
    } catch (e) {
      _uploadingFiles.clear();
      updateUploadStatus(UploadStatus.error, error: 'Failed to pick file: $e');
      return 'Failed to pick file: $e';
    }
  }

  void _deleteFile(String path) {
    try {
      if (path.startsWith('http') || path.startsWith('https')) return;
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
        if (kDebugMode) print('Deleted physical file: $path');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to delete physical file $path: $e');
    }
  }

  void removeFile(List<dynamic> current, dynamic entry) {
    // Physical delete only for local files
    if (entry is FileData && entry.localPath != null) {
      _deleteFile(entry.localPath!);
    } else if (entry is String) {
      _deleteFile(entry);
    }
    final updated = List<dynamic>.from(current)..remove(entry);
    formController.updateValue(
      component.key,
      updated.isEmpty
          ? null
          : component.multiple
              ? updated
              : updated.first,
    );
  }
}
