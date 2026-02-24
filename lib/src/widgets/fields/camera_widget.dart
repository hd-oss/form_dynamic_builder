import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

// ---------------------------------------------------------------------------
// Helper: burn metadata text onto the captured photo using dart:ui Canvas
// ---------------------------------------------------------------------------

Future<String> _burnMetadataOntoPhoto({
  required String imagePath,
  required bool showTimestamp,
  required String timestampFormat,
  required bool showCoordinates,
  required bool showDeviceInfo,
}) async {
  // ---- Build the annotation lines ----------------------------------------
  final lines = <String>[];
  if (showTimestamp) {
    lines.add(_formatDateTime(DateTime.now(), timestampFormat));
  }
  if (showCoordinates) {
    lines.add(await _getGpsCoordinates());
  }
  if (showDeviceInfo) {
    lines.add('Device: ${Platform.operatingSystem}');
  }

  if (lines.isEmpty) return imagePath; // nothing to draw

  // ---- Decode the original image ------------------------------------------
  final bytes = await File(imagePath).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final original = frame.image;

  final imgW = original.width.toDouble();
  final imgH = original.height.toDouble();

  // ---- Draw onto a Canvas -------------------------------------------------
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW, imgH));

  // Draw the original photo
  canvas.drawImage(original, Offset.zero, Paint());

  // We'll place the text block in the bottom-left corner.
  const double fontSize = 32.0;
  const double padding = 16.0;
  const double lineSpacing = 8.0;

  final textStyle = ui.ParagraphStyle(
    textDirection: TextDirection.ltr,
  );
  final textDecoration = ui.TextStyle(
    color: const Color(0xFFFFFFFF),
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    shadows: [
      const ui.Shadow(
        offset: Offset(1.5, 1.5),
        blurRadius: 4,
        color: Color(0xFF000000),
      ),
    ],
  );

  // Measure each line and compute block height
  final painters = <ui.Paragraph>[];
  double blockH = padding;
  double blockW = 0;
  for (final line in lines) {
    final pb = ui.ParagraphBuilder(textStyle)
      ..pushStyle(textDecoration)
      ..addText(line);
    final paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: imgW - padding * 2));
    painters.add(paragraph);
    blockH += paragraph.height + lineSpacing;
    if (paragraph.longestLine > blockW) blockW = paragraph.longestLine;
  }
  blockH += padding;
  blockW += padding * 2;

  // Semi-transparent background rectangle
  final bgPaint = Paint()..color = const Color(0x99000000);
  final bgRect = Rect.fromLTWH(
    padding,
    imgH - blockH - padding,
    blockW,
    blockH,
  );
  final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(8));
  canvas.drawRRect(rrect, bgPaint);

  // Paint each text line
  double yOffset = bgRect.top + padding;
  for (final paragraph in painters) {
    canvas.drawParagraph(paragraph, Offset(padding * 2, yOffset));
    yOffset += paragraph.height + lineSpacing;
  }

  // ---- Encode and save ----------------------------------------------------
  final picture = recorder.endRecording();
  final annotated = await picture.toImage(original.width, original.height);
  final byteData = await annotated.toByteData(format: ui.ImageByteFormat.png);

  final outPath =
      '${Directory.systemTemp.path}/photo_annotated_${DateTime.now().millisecondsSinceEpoch}.png';
  await File(outPath).writeAsBytes(byteData!.buffer.asUint8List());

  return outPath;
}

String _formatDateTime(DateTime dt, String format) {
  return format
      .replaceAll('yyyy', dt.year.toString().padLeft(4, '0'))
      .replaceAll('MM', dt.month.toString().padLeft(2, '0'))
      .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
      .replaceAll('HH', dt.hour.toString().padLeft(2, '0'))
      .replaceAll('mm', dt.minute.toString().padLeft(2, '0'))
      .replaceAll('ss', dt.second.toString().padLeft(2, '0'))
      .replaceAll('s', dt.second.toString());
}

Future<String> _getGpsCoordinates() async {
  // Check if location service is enabled
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return 'GPS: Service Off';

  // Check / request permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return 'GPS: Denied';
  }
  if (permission == LocationPermission.deniedForever) {
    return 'GPS: Denied Forever';
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);
    return 'GPS: $lat, $lng';
  } catch (e) {
    return 'GPS: N/A';
  }
}

// ---------------------------------------------------------------------------
// DynamicCamera — form field widget
// ---------------------------------------------------------------------------

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

    // Select initial camera based on cameraFacing setting
    CameraDescription initialCamera;
    if (component.cameraFacing == 'front') {
      initialCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    } else if (component.cameraFacing == 'rear') {
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
          allowSwitch: component.cameraFacing == 'both',
        ),
      ),
    );

    if (rawPath == null || !context.mounted) return;

    // Burn metadata onto the photo after capture
    final finalPath = await _burnMetadataOntoPhoto(
      imagePath: rawPath,
      showTimestamp: component.showTimestamp,
      timestampFormat: component.timestampFormat,
      showCoordinates: component.showCoordinates,
      showDeviceInfo: component.showDeviceInfo,
    );

    if (context.mounted) {
      controller.updateValue(component.key, finalPath);
    }
  }

  void _clearPhoto() {
    controller.updateValue(component.key, null);
  }

  Widget _buildInfoBadge(BuildContext context) {
    final parts = <String>[];
    if (component.showTimestamp) parts.add('Timestamp');
    if (component.showCoordinates) parts.add('Coordinates');
    if (component.showDeviceInfo) parts.add('Device Info');
    if (component.compressFile) parts.add('Compressed');

    final isImmediate = component.uploadTiming == 'immediate';

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
