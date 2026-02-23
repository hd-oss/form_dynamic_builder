import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

class DynamicFile extends StatelessWidget {
  final FileComponent component;
  final FormController controller;

  const DynamicFile({
    super.key,
    required this.component,
    required this.controller,
  });

  String _formatMaxSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _buildHelperText() {
    final parts = <String>[];
    if (component.accept.isNotEmpty) {
      parts.add('Accepted: ${component.accept.toUpperCase()}');
    }
    if (component.maxSize > 0) {
      parts.add('Max: ${_formatMaxSize(component.maxSize)}');
    }
    if (component.multiple) {
      parts.add('Multiple files allowed');
    }
    return parts.join(' · ');
  }

  Future<void> _pickFiles(BuildContext context, List<String> current) async {
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
            if (component.maxSize > 0) {
              if (file.size > component.maxSize) {
                if (context.mounted) {
                  _showError(context,
                      '${file.name} exceeds max size of ${_formatMaxSize(component.maxSize)}');
                }
                continue;
              }
            }
            if (file.path != null && !current.contains(file.path!)) {
              current = [...current, file.path!];
            }
          }
          if (context.mounted) {
            controller.updateValue(component.key, current);
          }
        } else {
          final file = result.files.first;
          if (component.maxSize > 0 && file.size > component.maxSize) {
            if (context.mounted) {
              _showError(context,
                  '${file.name} exceeds max size of ${_formatMaxSize(component.maxSize)}');
            }
            return;
          }
          if (context.mounted && file.path != null) {
            controller.updateValue(component.key, file.path);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to pick file: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final helperText = _buildHelperText();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final value = controller.getValue(component.key);
          final selectedFiles = value is List
              ? List<String>.from(value)
              : (value != null ? [value.toString()] : <String>[]);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                  helperText: helperText.isNotEmpty ? helperText : null,
                ),
                child: Focus(
                  focusNode: controller.getFocusNode(component.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedFiles.isNotEmpty) ...[
                        ...selectedFiles.map(
                          (filePath) {
                            final fileName =
                                filePath.split(Platform.pathSeparator).last;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!component.disabled)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        final updated =
                                            List<String>.from(selectedFiles)
                                              ..remove(filePath);
                                        controller.updateValue(
                                          component.key,
                                          updated.isEmpty
                                              ? null
                                              : component.multiple
                                                  ? updated
                                                  : updated.first,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!component.disabled &&
                          (component.multiple || selectedFiles.isEmpty))
                        ElevatedButton.icon(
                          onPressed: () => _pickFiles(context, selectedFiles),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                              component.multiple ? 'Add File' : 'Upload File'),
                        ),
                    ],
                  ),
                ),
              ),
              if (component.uploadUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Upload to: ${component.uploadUrl}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
