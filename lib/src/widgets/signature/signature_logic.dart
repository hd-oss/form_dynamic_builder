import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/file_data.dart';
import '../../utils/file_utils.dart';

import '../../services/mixins/upload_mixin.dart';
import '../../services/upload_service.dart';

class SignatureLogic extends ChangeNotifier with UploadMixin {
  final SignatureComponent component;
  final FormController formController;

  late final SignatureController signatureController;

  SignatureLogic(this.component, this.formController) {
    signatureController = SignatureController(
      penColor: Colors.black,
      penStrokeWidth: 3.0,
      exportBackgroundColor: Colors.white,
    );
    signatureController.onDrawEnd = saveSignature;

    formController.addListener(_onFormControllerChanged);
  }

  void _onFormControllerChanged() {
    final value = formController.getValue(component.key);
    if (value == null && signatureController.isNotEmpty) {
      signatureController.clear();
      notifyListeners();
    }
    // Note: Loading a base64 string back into the canvas is complex and
    // usually not supported out-of-the-box by the signature package without
    // creating a custom image provider. For now, we mainly support clearing
    // the signature if the form is reset or dependency changes.
  }

  @override
  void dispose() {
    formController.removeListener(_onFormControllerChanged);
    signatureController.dispose();
    super.dispose();
  }

  Future<void> saveSignature() async {
    if (signatureController.isEmpty) {
      formController.updateValue(component.key, null);
      updateUploadStatus(UploadStatus.idle);
      return;
    }

    final data = await signatureController.toPngBytes();
    if (data != null) {
      updateUploadStatus(UploadStatus.uploading);
      if (component.uploadTiming == 'immediate' &&
          component.uploadUrl.isNotEmpty) {
        // Save to temporary file for upload
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(data);

        // Move to persistent storage
        final persistentPath = await FileStorageUtils.moveToSupportDirectory(
          tempFile.path,
          subDir: 'signatures',
        );

        final uploadResult = await UploadService.processAndUpload(
          localPaths: [persistentPath],
          formController: formController,
          uploadUrl: component.uploadUrl,
          uploadTiming: component.uploadTiming,
          uploadType: component.uploadType,
          uploadConfig: component.uploadConfig,
          compressFile: false, // Signature is already processed to PNG
          maxSize: 0,
        );

        if (uploadResult.isSuccess) {
          final resultValue = uploadResult.values.first;
          final size = File(persistentPath).existsSync()
              ? File(persistentPath).lengthSync()
              : null;
          final fileData = FileData.fromUpload(
            localPath: persistentPath,
            size: size,
            uploadedUrl: component.uploadUrl,
            uploadResponse: extractValueFromPath(
              resultValue,
              component.uploadConfig?.responseFileUrlPath ?? '',
            ),
          );
          formController.updateValue(component.key, fileData);
          updateUploadStatus(UploadStatus.success);
        } else {
          // Fallback to base64 if upload fails
          final base64String = base64Encode(data);
          formController.updateValue(component.key, base64String);
          updateUploadStatus(UploadStatus.error,
              error: uploadResult.errorMessage);
        }
      } else {
        // Default behavior: save as base64 string
        final base64String = base64Encode(data);
        formController.updateValue(component.key, base64String);
        updateUploadStatus(UploadStatus.success);
      }
    }
  }

  Future<void> clearSignature() async {
    final value = formController.getValue(component.key);
    if (value is FileData && value.localPath != null) {
      if (await FileStorageUtils.isSafeToDelete(value.localPath!)) {
        try {
          final file = File(value.localPath!);
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    signatureController.clear();
    formController.updateValue(component.key, null);
  }

  // ==========================================================================
  // IMAGE HELPERS (Moved from Widget)
  // ==========================================================================

  bool isExternalImage(FileData? value) {
    if (value == null) return false;
    return (value.localPath != null) && signatureController.isEmpty;
  }

  Widget buildImageFromValue(BuildContext context, FileData? value,
      {double? height, double? width}) {
    String? val = value?.localPath;

    if (val == null || val.isEmpty) {
      return const Center(child: Icon(Icons.broken_image));
    }

    try {
      if (val.contains(',')) {
        final base64Str = val.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)),
        );
      }

      if (RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(val)) {
        return Image.memory(
          base64Decode(val),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)),
        );
      }
    } catch (_) {}

    return const Center(child: Icon(Icons.broken_image));
  }
}
