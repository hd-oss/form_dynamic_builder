import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreenLogic extends ChangeNotifier {
  final List<CameraDescription> cameras;
  final CameraDescription initialCamera;

  late CameraController controller;
  late CameraDescription activeCamera;

  bool isReady = false;
  bool isTaking = false;
  FlashMode flashMode = FlashMode.auto;
  bool _isDisposed = false;

  CameraScreenLogic({
    required this.cameras,
    required this.initialCamera,
  }) {
    activeCamera = initialCamera;
    _initializeCamera(activeCamera);
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    isReady = false;
    notifyListeners();

    controller = CameraController(camera, ResolutionPreset.high);

    try {
      await controller.initialize();
      if (_isDisposed) return;
      await controller.setFlashMode(flashMode);
      if (_isDisposed) return;
      isReady = true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    controller.dispose();
    super.dispose();
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    final next = cameras.firstWhere(
      (c) => c.lensDirection != activeCamera.lensDirection,
      orElse: () => activeCamera,
    );
    activeCamera = next;
    await controller.setDescription(next);
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (!isReady) return;

    FlashMode nextMode;
    switch (flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      default:
        nextMode = FlashMode.off;
    }

    try {
      await controller.setFlashMode(nextMode);
      flashMode = nextMode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  IconData getFlashIcon() {
    switch (flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  Future<String?> takePicture() async {
    if (!controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        isTaking) {
      return null;
    }

    isTaking = true;
    notifyListeners();

    try {
      final XFile file = await controller.takePicture();
      return file.path;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    } finally {
      isTaking = false;
      notifyListeners();
    }
  }
}
