import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_screen_logic.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraDescription initialCamera;
  final bool allowSwitch;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.initialCamera,
    required this.allowSwitch,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CameraScreenLogic logic;

  @override
  void initState() {
    super.initState();
    logic = CameraScreenLogic(
      cameras: widget.cameras,
      initialCamera: widget.initialCamera,
    );
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        if (!logic.isReady) {
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
              IconButton(
                icon: Icon(logic.getFlashIcon()),
                tooltip: 'Toggle Flash',
                onPressed: logic.toggleFlash,
              ),
              if (widget.allowSwitch && widget.cameras.length > 1)
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios),
                  tooltip: 'Switch Camera',
                  onPressed: logic.switchCamera,
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final scale =
                  1 / (logic.controller.value.aspectRatio * size.aspectRatio);

              return Stack(
                children: [
                  ClipRect(
                    child: Transform.scale(
                      scale: scale < 1 ? 1 / scale : scale,
                      child: Center(
                        child: CameraPreview(logic.controller),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: logic.isTaking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : FloatingActionButton(
                              onPressed: () async {
                                final path = await logic.takePicture();
                                if (path != null && context.mounted) {
                                  Navigator.pop(context, path);
                                }
                              },
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.black),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
