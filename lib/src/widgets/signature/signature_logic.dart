import 'dart:convert';

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
  }

  @override
  void dispose() {
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
      final base64String = base64Encode(data);
      formController.updateValue(component.key, base64String);
    }
  }

  void clearSignature() {
    signatureController.clear();
    formController.updateValue(component.key, null);
  }
}
