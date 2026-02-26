import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../mixins/data_source_mixin.dart';

class SignatureLogic extends ChangeNotifier with DataSourceMixin {
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

    initDefaultValue(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
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
    disposeDataSource();
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
