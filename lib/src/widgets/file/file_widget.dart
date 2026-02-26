import 'dart:io';

import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'file_logic.dart';

class DynamicFile extends StatefulWidget {
  final FileComponent component;
  final FormController controller;

  const DynamicFile({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicFile> createState() => _DynamicFileState();
}

class _DynamicFileState extends State<DynamicFile> {
  late final FileLogic logic;

  @override
  void initState() {
    super.initState();
    logic = FileLogic(widget.component, widget.controller);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  Future<void> _handlePickFiles(
      BuildContext context, List<String> current) async {
    final error = await logic.pickFiles(current);
    if (error != null && context.mounted) {
      _showError(context, error);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final helperText = logic.buildHelperText();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
          final value = widget.controller.getValue(widget.component.key);
          final selectedFiles = value is List
              ? List<String>.from(value)
              : (value != null ? [value.toString()] : <String>[]);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                  helperText: helperText.isNotEmpty ? helperText : null,
                ),
                child: logic.isLoadingDefaultValue
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : logic.defaultValueError != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Failed to load data',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 13),
                            ),
                          )
                        : Focus(
                            focusNode: widget.controller
                                .getFocusNode(widget.component.key),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedFiles.isNotEmpty) ...[
                                  ...selectedFiles.map(
                                    (filePath) {
                                      final fileName = filePath
                                          .split(Platform.pathSeparator)
                                          .last;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.insert_drive_file,
                                                size: 16),
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
                                            if (!widget.component.disabled)
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    logic.removeFile(
                                                        selectedFiles,
                                                        filePath),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (!widget.component.disabled &&
                                    (widget.component.multiple ||
                                        selectedFiles.isEmpty))
                                  ElevatedButton.icon(
                                    onPressed: logic.isPicking
                                        ? null
                                        : () => _handlePickFiles(
                                            context, selectedFiles),
                                    icon: logic.isPicking
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.upload_file),
                                    label: Text(logic.isPicking
                                        ? 'Picking...'
                                        : (widget.component.multiple
                                            ? 'Add File'
                                            : 'Upload File')),
                                  ),
                              ],
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
