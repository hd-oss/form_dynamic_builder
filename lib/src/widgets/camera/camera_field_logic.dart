import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/file_data.dart';

import '../../utils/image_compressor.dart';
import '../../utils/file_utils.dart';

import '../../services/mixins/upload_mixin.dart';
import '../../services/upload_service.dart';

class CameraLogic extends ChangeNotifier with UploadMixin {
  final CameraComponent component;
  final FormController formController;

  bool _isDisposed = false;

  CameraLogic(this.component, this.formController) {
    // Initialization
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> clearPhoto() async {
    final value = formController.getValue(component.key);
    String? currentPath;
    if (value is FileData) {
      currentPath = value.localPath;
    } else if (value is String) {
      currentPath = value;
    }

    if (currentPath != null) {
      try {
        if (await FileStorageUtils.isSafeToDelete(currentPath)) {
          final file = File(currentPath);
          if (file.existsSync()) {
            file.deleteSync();
            if (kDebugMode) print('Deleted physical photo: $currentPath');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Failed to delete $currentPath: $e');
      }
    }
    formController.updateValue(component.key, null);
  }

  Future<void> processAndSavePhoto(String rawPath) async {
    updateUploadStatus(UploadStatus.uploading);

    try {
      String pathToProcess = rawPath;
      if (component.compressFile) {
        pathToProcess = await ImageCompressor.compressImage(
          imagePath: rawPath,
          quality: component.compressPercentage,
        );
      }

      final finalPath = await burnMetadataOntoPhoto(
        imagePath: pathToProcess,
        showTimestamp: component.showTimestamp,
        timestampFormat: component.timestampFormat,
        showCoordinates: component.showCoordinates,
        showDeviceInfo: component.showDeviceInfo,
      );
      if (_isDisposed) return;

      // Move to persistent storage
      final persistentPath = await FileStorageUtils.moveToSupportDirectory(
        finalPath,
        subDir: 'camera',
      );

      final uploadResult = await UploadService.processAndUpload(
        localPaths: [persistentPath],
        formController: formController,
        uploadUrl: component.uploadUrl,
        uploadTiming: component.uploadTiming,
        uploadType: component.uploadType,
        uploadConfig: component.uploadConfig,
        compressFile: false, // Already processed metadata burning
        maxSize: 0, // Camera quality usually handled by package
      );

      if (uploadResult.isSuccess) {
        final resultValue =
            uploadResult.values.isNotEmpty ? uploadResult.values.first : null;
        final size = File(persistentPath).existsSync()
            ? File(persistentPath).lengthSync()
            : null;

        final fileData = uploadResult.wasUploaded
            ? FileData.fromUpload(
                localPath: persistentPath,
                size: size,
                uploadedUrl: component.uploadUrl,
                uploadResponse: resultValue,
              )
            : FileData.fromLocalPath(persistentPath, size: size)
                .copyWith(uploadedUrl: component.uploadUrl);

        formController.updateValue(component.key, fileData);
        updateUploadStatus(uploadResult.wasUploaded
            ? UploadStatus.success
            : UploadStatus.idle);
      } else {
        // Fallback: keep local file wrapped in FileData
        final size = File(persistentPath).existsSync()
            ? File(persistentPath).lengthSync()
            : null;
        formController.updateValue(
            component.key,
            FileData.fromLocalPath(persistentPath, size: size)
                .copyWith(uploadedUrl: component.uploadUrl));
        updateUploadStatus(UploadStatus.error,
            error: uploadResult.errorMessage);
      }
    } catch (e) {
      updateUploadStatus(UploadStatus.error, error: 'Processing failed: $e');
    }
  }

  Future<String> burnMetadataOntoPhoto({
    required String imagePath,
    required bool showTimestamp,
    required String timestampFormat,
    required bool showCoordinates,
    required bool showDeviceInfo,
  }) async {
    final lines = <String>[];
    if (showTimestamp) {
      lines.add(formatDateTime(DateTime.now(), timestampFormat));
    }
    if (showCoordinates) {
      lines.add(await getGpsCoordinates());
    }
    if (showDeviceInfo) {
      lines.add('Device: ${Platform.operatingSystem}');
    }

    if (lines.isEmpty) return imagePath;

    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;

    final imgW = original.width.toDouble();
    final imgH = original.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW, imgH));

    canvas.drawImage(original, Offset.zero, Paint());

    const double fontSize = 32.0;
    const double padding = 16.0;
    const double lineSpacing = 8.0;

    final textStyle = ui.ParagraphStyle(textDirection: TextDirection.ltr);
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

    final bgPaint = Paint()..color = const Color(0x99000000);
    final bgRect =
        Rect.fromLTWH(padding, imgH - blockH - padding, blockW, blockH);
    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    double yOffset = bgRect.top + padding;
    for (final paragraph in painters) {
      canvas.drawParagraph(paragraph, Offset(padding * 2, yOffset));
      yOffset += paragraph.height + lineSpacing;
    }

    final picture = recorder.endRecording();
    final annotated = await picture.toImage(original.width, original.height);
    final byteData = await annotated.toByteData(format: ui.ImageByteFormat.png);

    final outPath =
        '${Directory.systemTemp.path}/photo_annotated_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(byteData!.buffer.asUint8List());

    return outPath;
  }

  String formatDateTime(DateTime dt, String format) {
    return format
        .replaceAll('yyyy', dt.year.toString().padLeft(4, '0'))
        .replaceAll('MM', dt.month.toString().padLeft(2, '0'))
        .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
        .replaceAll('HH', dt.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', dt.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', dt.second.toString().padLeft(2, '0'))
        .replaceAll('s', dt.second.toString());
  }

  Future<String> getGpsCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'GPS: Service Off';

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

  Widget buildImageFromValue(FileData? value, bool isPreview) {
    if (value == null || value.localPath == null || value.localPath!.isEmpty) {
      return const Center(child: Icon(Icons.broken_image));
    }

    return Image.file(
      File(value.localPath!),
      fit: isPreview ? BoxFit.fill : BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }
}
