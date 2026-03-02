import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';

class SignatureLogic extends ChangeNotifier {
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
      return;
    }

    final data = await signatureController.toPngBytes();
    if (data != null) {
      if (component.uploadTiming == 'immediate' &&
          formController.config.onFileUpload != null &&
          component.uploadUrl.isNotEmpty) {
        // Save to temporary file for upload
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(data);

        final remoteUrl = await formController.config.onFileUpload!(
          tempFile.path,
          component.uploadUrl,
        );

        if (remoteUrl != null) {
          formController.updateValue(component.key, remoteUrl);
        } else {
          // Fallback to base64 if upload fails
          final base64String = base64Encode(data);
          formController.updateValue(component.key, base64String);
        }
      } else {
        // Default behavior: save as base64 string
        final base64String = base64Encode(data);
        formController.updateValue(component.key, base64String);
      }
    }
  }

  void clearSignature() {
    signatureController.clear();
    formController.updateValue(component.key, null);
  }
}
