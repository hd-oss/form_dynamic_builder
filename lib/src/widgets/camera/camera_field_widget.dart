import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../services/mixins/upload_mixin.dart';
import '../../models/components/all_components.dart';
import '../../models/file_data.dart';
import '../field_label.dart';
import 'camera_field_logic.dart';
import 'camera_screen_widget.dart';

// ============================================================================
// DynamicCamera Field Widget
// ============================================================================

class DynamicCamera extends StatefulWidget {
  final CameraComponent component;
  final FormController controller;

  const DynamicCamera({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicCamera> createState() => _DynamicCameraState();
}

class _DynamicCameraState extends State<DynamicCamera> {
  late final CameraLogic logic;

  @override
  void initState() {
    super.initState();
    logic = CameraLogic(widget.component, widget.controller);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CAMERA ACTIONS
  // ==========================================================================

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return _showNoCameraMessage();

    final cam = _selectInitialCamera(cameras);
    if (!mounted) return;

    final rawPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cameras: cameras,
          initialCamera: cam,
          allowSwitch: widget.component.cameraFacing == 'both',
        ),
      ),
    );

    if (rawPath == null || !mounted) return;
    await logic.processAndSavePhoto(rawPath);
  }

  void _showNoCameraMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No cameras available')),
    );
  }

  CameraDescription _selectInitialCamera(List<CameraDescription> cameras) {
    final facing = widget.component.cameraFacing;

    if (facing == 'front') {
      return cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    }

    return cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  // ==========================================================================
  // UI BUILDERS
  // ==========================================================================

  Widget _buildPreview(FileData? value) {
    return GestureDetector(
      onTap: () => _openPreviewDialog(value),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: logic.buildImageFromValue(value),
        ),
      ),
    );
  }

  void _openPreviewDialog(FileData? value) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: logic.buildImageFromValue(value),
            ),
            Positioned(
              top: 16,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakePhotoButton() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: IconButton(
          iconSize: 48,
          icon: const Icon(Icons.camera_alt),
          onPressed: widget.component.disabled ? null : _openCamera,
          tooltip: 'Take Photo',
        ),
      ),
    );
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
          final value = widget.controller.getValue(widget.component.key);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                ),
                child: Focus(
                  focusNode:
                      widget.controller.getFocusNode(widget.component.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (logic.uploadStatus == UploadStatus.uploading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 4),
                            ),
                          ),
                        ),
                      if (logic.uploadStatus == UploadStatus.error)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  logic.uploadError ?? 'Upload failed',
                                  style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (value is FileData) ...[
                        Stack(children: [
                          _buildPreview(value),
                          if (value.isUploaded)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_done,
                                    color: Colors.green, size: 24),
                              ),
                            ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: widget.component.disabled
                                    ? null
                                    : logic.clearPhoto,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.5),
                                )),
                          ),
                        ]),
                      ] else
                        _buildTakePhotoButton(),
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
