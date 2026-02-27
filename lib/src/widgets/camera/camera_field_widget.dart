import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'camera_field_logic.dart';
import 'camera_screen_widget.dart';
import '../common/data_source_state_builder.dart';

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

  Widget _buildPreview(String filePath) {
    return GestureDetector(
      onTap: () => _openPreviewDialog(filePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          File(filePath),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _openPreviewDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(File(filePath), fit: BoxFit.contain),
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

  Widget _buildProcessingPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildRemoveButton() {
    return OutlinedButton.icon(
      onPressed: logic.clearPhoto,
      icon: const Icon(Icons.delete),
      label: const Text('Remove Photo'),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
    );
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DataSourceStateBuilder(
        logic: logic,
        component: widget.component,
        builder: (context) {
          final value =
              widget.controller.getValue(widget.component.key) as String?;

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
                      if (logic.isProcessing)
                        _buildProcessingPlaceholder()
                      else if (value != null && value.isNotEmpty) ...[
                        _buildPreview(value),
                        const SizedBox(height: 8),
                        if (!widget.component.disabled) _buildRemoveButton(),
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
