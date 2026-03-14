import 'dart:io';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/file_data.dart';
import '../common/adaptive_button.dart';
import '../../services/mixins/upload_mixin.dart';
import '../field_label.dart';
import 'file_upload_logic.dart';

class DynamicFileUpload extends StatefulWidget {
  final FileUploadComponent component;
  final FormController controller;

  const DynamicFileUpload({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicFileUpload> createState() => _DynamicFileUploadState();
}

class _DynamicFileUploadState extends State<DynamicFileUpload> {
  late final FileUploadLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = FileUploadLogic(widget.component, widget.controller);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  List<FileData> _getSelectedFiles() {
    final value = widget.controller.getValue(widget.component.key);
    if (value is List) {
      return value.map((e) {
        if (e is FileData) return e;
        if (e is Map<String, dynamic>) return FileData.fromJson(e);
        return FileData(
          name: e.toString().split('/').last,
          localPath: e.toString(),
          uploadedUrl: null,
          status: 'local',
        );
      }).toList();
    }
    if (value is FileData) return [value];
    if (value is Map<String, dynamic>) return [FileData.fromJson(value)];
    if (value != null) {
      final str = value.toString();
      return [
        FileData(
          name: str.split('/').last,
          localPath: str,
          uploadedUrl: null,
          status: 'local',
        )
      ];
    }
    return [];
  }

  Widget _buildFileList(List<FileData> files, List<String> uploading) {
    if (files.isEmpty && uploading.isEmpty) return const SizedBox();

    return Column(
      children: [
        // Completed files
        ...files.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.component.multiple ? 8 : 0),
            child: Row(children: [
              Icon(
                  entry.isUploaded
                      ? Icons.cloud_done
                      : Icons.insert_drive_file_rounded,
                  color: entry.isUploaded
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.name, // ← always from local file selection
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.component.disabled)
                InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => _logic.removeFile(_getSelectedFiles(), entry),
                    child: const Icon(Icons.close, size: 18)),
            ]),
          );
        }),

        // Uploading Files
        ...uploading.map((filePath) {
          final fileName = filePath.split(Platform.pathSeparator).last;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(strokeWidth: 3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 40), // Space for matching alignment
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildUploadButton(List<FileData> selectedFiles, bool isUploading) {
    final canUpload =
        !isUploading && (widget.component.multiple || selectedFiles.isEmpty);

    if (!canUpload) return const SizedBox();

    return Padding(
      padding: EdgeInsets.zero,
      child: AdaptiveButton(
          onPressed: widget.component.disabled
              ? null
              : () async => await _logic.pickFiles(selectedFiles),
          icon: const Icon(Icons.upload_file),
          child: Text(
            widget.component.multiple ? 'Add File' : 'Upload File',
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final helperText = _logic.buildHelperText();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, _logic]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(component: widget.component),
            InputDecorator(
                decoration: InputDecoration(
                    border: InputBorder.none,
                    errorText: widget.controller.errors[widget.component.key],
                    helperText: helperText.isNotEmpty ? helperText : null),
                child: Focus(
                  focusNode:
                      widget.controller.getFocusNode(widget.component.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_logic.uploadStatus == UploadStatus.error)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _logic.uploadError ?? 'Upload failed',
                                  style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Builder(builder: (context) {
                        final files = _getSelectedFiles();
                        final uploading = _logic.uploadingFiles;
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFileList(files, uploading),
                              _buildUploadButton(files, uploading.isNotEmpty),
                            ]);
                      }),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
