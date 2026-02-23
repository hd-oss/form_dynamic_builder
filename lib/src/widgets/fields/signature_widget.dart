import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

class DynamicSignature extends StatefulWidget {
  final SignatureComponent component;
  final FormController controller;

  const DynamicSignature({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicSignature> createState() => _DynamicSignatureState();
}

class _DynamicSignatureState extends State<DynamicSignature> {
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penColor: Colors.black,
      penStrokeWidth: 3.0,
      exportBackgroundColor: Colors.white,
    );

    _signatureController.onDrawEnd = _saveSignature;
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      widget.controller.updateValue(widget.component.key, null);
      return;
    }

    final data = await _signatureController.toPngBytes();
    if (data != null) {
      final base64String = base64Encode(data);
      widget.controller.updateValue(widget.component.key, base64String);
    }
  }

  void _clearSignature() {
    _signatureController.clear();
    widget.controller.updateValue(widget.component.key, null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed:
                        widget.component.disabled ? null : _clearSignature,
                    tooltip: 'Clear Signature',
                  ),
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  height: widget.component.height ?? 150,
                  width: widget.component.width ?? double.infinity,
                  child: Signature(
                    controller: _signatureController,
                    height: widget.component.height ?? 150,
                    width: widget.component.width ?? double.infinity,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              if (widget.component.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    widget.component.description,
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
