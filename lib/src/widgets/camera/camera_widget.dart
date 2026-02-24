import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'camera_logic.dart';

// ---------------------------------------------------------------------------
// DynamicCamera — form field widget
// ---------------------------------------------------------------------------

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

  Future<void> _openCamera(BuildContext context) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras available')),
        );
      }
      return;
    }

    // Select initial camera based on cameraFacing setting
    CameraDescription initialCamera;
    if (widget.component.cameraFacing == 'front') {
      initialCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    } else if (widget.component.cameraFacing == 'rear') {
      initialCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    } else {
      initialCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    }

    if (!context.mounted) return;

    final rawPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => _CameraScreen(
          cameras: cameras,
          initialCamera: initialCamera,
          allowSwitch: widget.component.cameraFacing == 'both',
        ),
      ),
    );

    if (rawPath == null || !context.mounted) return;

    // Burn metadata onto the photo after capture using logic
    await logic.processAndSavePhoto(rawPath);
  }

  Widget _buildInfoBadge(BuildContext context) {
    final parts = <String>[];
    if (widget.component.showTimestamp) parts.add('Timestamp');
    if (widget.component.showCoordinates) parts.add('Coordinates');
    if (widget.component.showDeviceInfo) parts.add('Device Info');
    if (widget.component.compressFile) parts.add('Compressed');

    final isImmediate = widget.component.uploadTiming == 'immediate';

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parts.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: parts
                  .map(
                    (label) => Chip(
                      label: Text(label,
                          style: Theme.of(context).textTheme.labelSmall),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isImmediate ? Icons.bolt : Icons.send,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                isImmediate ? 'Uploaded immediately' : 'Uploaded on submit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
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
                      if (logic.isProcessing) ...[
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ] else if (value != null && value.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(value),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!widget.component.disabled)
                          OutlinedButton.icon(
                            onPressed: logic.clearPhoto,
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ] else ...[
                        Container(
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
                              onPressed: widget.component.disabled
                                  ? null
                                  : () => _openCamera(context),
                              tooltip: 'Take Photo',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildInfoBadge(context),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CameraScreen — full-screen camera viewfinder (clean, no overlay)
// ---------------------------------------------------------------------------

class _CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraDescription initialCamera;
  final bool allowSwitch;

  const _CameraScreen({
    required this.cameras,
    required this.initialCamera,
    required this.allowSwitch,
  });

  @override
  State<_CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<_CameraScreen> {
  late CameraController _controller;
  late CameraDescription _activeCamera;
  bool _isReady = false;
  bool _isTaking = false;

  @override
  void initState() {
    super.initState();
    _activeCamera = widget.initialCamera;
    _initializeCamera(_activeCamera);
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    if (_isReady) {
      await _controller.dispose();
    }
    final controller = CameraController(camera, ResolutionPreset.high);
    _controller = controller;
    try {
      await _controller.initialize();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
    if (!mounted) return;
    setState(() {
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    setState(() => _isReady = false);
    final next = widget.cameras.firstWhere(
      (c) => c.lensDirection != _activeCamera.lensDirection,
      orElse: () => _activeCamera,
    );
    _activeCamera = next;
    await _initializeCamera(next);
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized ||
        _controller.value.isTakingPicture ||
        _isTaking) {
      return;
    }
    setState(() => _isTaking = true);
    try {
      final XFile file = await _controller.takePicture();
      if (mounted) {
        // Return raw path — metadata burning happens in DynamicCamera._openCamera
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take a Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (widget.allowSwitch && widget.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              tooltip: 'Switch Camera',
              onPressed: _isReady ? _switchCamera : null,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _isTaking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : FloatingActionButton(
                      onPressed: _takePicture,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.camera_alt, color: Colors.black),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
