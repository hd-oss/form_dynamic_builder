import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';

class CameraLogic extends ChangeNotifier {
  final CameraComponent component;
  final FormController formController;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  CameraLogic(this.component, this.formController);

  void clearPhoto() {
    formController.updateValue(component.key, null);
  }

  Future<void> processAndSavePhoto(String rawPath) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final finalPath = await burnMetadataOntoPhoto(
        imagePath: rawPath,
        showTimestamp: component.showTimestamp,
        timestampFormat: component.timestampFormat,
        showCoordinates: component.showCoordinates,
        showDeviceInfo: component.showDeviceInfo,
      );
      formController.updateValue(component.key, finalPath);
    } finally {
      _isProcessing = false;
      notifyListeners();
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
}
