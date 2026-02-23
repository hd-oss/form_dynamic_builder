import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

class DynamicCamera extends StatelessWidget {
  final CameraComponent component;
  final FormController controller;

  const DynamicCamera({
    super.key,
    required this.component,
    required this.controller,
  });

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

    if (!context.mounted) return;

    final imagePath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => _CameraScreen(cameras: cameras),
      ),
    );

    if (imagePath != null && context.mounted) {
      controller.updateValue(component.key, imagePath);
    }
  }

  void _clearPhoto() {
    controller.updateValue(component.key, null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final value = controller.getValue(component.key) as String?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                ),
                child: Focus(
                  focusNode: controller.getFocusNode(component.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (value != null && value.isNotEmpty) ...[
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
                        if (!component.disabled)
                          OutlinedButton.icon(
                            onPressed: _clearPhoto,
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
                              onPressed: component.disabled
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
              if (component.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    component.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const _CameraScreen({required this.cameras});

  @override
  State<_CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<_CameraScreen> {
  late CameraController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await _controller.takePicture();
      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
      }
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }
}
