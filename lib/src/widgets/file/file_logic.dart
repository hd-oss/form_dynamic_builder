import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../utils/image_compressor.dart';

class FileLogic extends ChangeNotifier {
  final FileComponent component;
  final FormController formController;

  bool _isPicking = false;
  bool get isPicking => _isPicking;

  FileLogic(this.component, this.formController) {
    // FileComponent no longer supports dataSource
    // initDefaultValue(
    //   dataSource: component.dataSource,
    //   controller: controller,
    //   componentKey: component.key,
    // );
  }

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

  Future<String?> pickFiles(List<String> current) async {
    _isPicking = true;
    notifyListeners();

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
        if (component.multiple) {
          for (final file in result.files) {
            if (component.maxSize > 0 && file.size > component.maxSize) {
              return '${file.name} exceeds max size of ${formatMaxSize(component.maxSize)}';
            }
            if (file.path != null && !current.contains(file.path!)) {
              String filePath = file.path!;
              if (component.compressFile) {
                filePath = await ImageCompressor.compressImage(
                  imagePath: filePath,
                  quality: component.compressPercentage,
                );
              }

              if (component.uploadTiming == 'immediate' &&
                  formController.config.onFileUpload != null &&
                  component.uploadUrl.isNotEmpty) {
                final remoteUrl = await formController.config.onFileUpload!(
                  filePath,
                  component.uploadUrl,
                );
                if (remoteUrl != null) {
                  current = [...current, remoteUrl];
                } else {
                  current = [...current, filePath];
                }
              } else {
                current = [...current, filePath];
              }
            }
          }
          formController.updateValue(component.key, current);
        } else {
          final file = result.files.first;
          if (component.maxSize > 0 && file.size > component.maxSize) {
            return '${file.name} exceeds max size of ${formatMaxSize(component.maxSize)}';
          }
          if (file.path != null) {
            String filePath = file.path!;
            if (component.compressFile) {
              filePath = await ImageCompressor.compressImage(
                imagePath: filePath,
                quality: component.compressPercentage,
              );
            }

            if (component.uploadTiming == 'immediate' &&
                formController.config.onFileUpload != null &&
                component.uploadUrl.isNotEmpty) {
              final remoteUrl = await formController.config.onFileUpload!(
                filePath,
                component.uploadUrl,
              );
              if (remoteUrl != null) {
                formController.updateValue(component.key, remoteUrl);
              } else {
                formController.updateValue(component.key, filePath);
              }
            } else {
              formController.updateValue(component.key, filePath);
            }
          }
        }
      }
      return null;
    } catch (e) {
      return 'Failed to pick file: $e';
    } finally {
      _isPicking = false;
      notifyListeners();
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

  void removeFile(List<String> current, String filePath) {
    _deleteFile(filePath);
    final updated = List<String>.from(current)..remove(filePath);
    formController.updateValue(
      component.key,
      updated.isEmpty
          ? null
          : component.multiple
              ? updated
              : updated.first,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
