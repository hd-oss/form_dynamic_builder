import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../mixins/data_source_mixin.dart';

class FileLogic extends ChangeNotifier with DataSourceMixin {
  final FileComponent component;
  final FormController formController;

  bool _isPicking = false;
  bool get isPicking => _isPicking;

  FileLogic(this.component, this.formController) {
    initDefaultValue(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
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
              current = [...current, file.path!];
            }
          }
          formController.updateValue(component.key, current);
        } else {
          final file = result.files.first;
          if (component.maxSize > 0 && file.size > component.maxSize) {
            return '${file.name} exceeds max size of ${formatMaxSize(component.maxSize)}';
          }
          if (file.path != null) {
            formController.updateValue(component.key, file.path);
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

  void removeFile(List<String> current, String filePath) {
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
    disposeDataSource();
    super.dispose();
  }
}
