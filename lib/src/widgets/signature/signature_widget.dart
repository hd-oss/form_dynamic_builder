import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import '../common/data_source_state_builder.dart';
import 'signature_logic.dart';

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
  late final SignatureLogic logic;

  @override
  void initState() {
    super.initState();
    logic = SignatureLogic(widget.component, widget.controller);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // ==========================================================================
  // EXTERNAL IMAGE HANDLING
  // ==========================================================================

  bool _isExternalImage(dynamic value) {
    return value != null &&
        value is String &&
        value.isNotEmpty &&
        logic.signatureController.isEmpty;
  }

  Widget _buildExternalImage(String value) {
    final imageWidget = _decodeImage(value);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      height: widget.component.height ?? 150,
      width: widget.component.width ?? double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: imageWidget),
          if (widget.component.disabled)
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
        ],
      ),
    );
  }

  Widget _decodeImage(String val) {
    try {
      if (val.startsWith('http://') || val.startsWith('https://')) {
        return Image.network(
          val,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)),
        );
      }

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

  // ==========================================================================
  // SIGNATURE CANVAS BUILDER
  // ==========================================================================

  Widget _buildSignatureCanvas() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      height: widget.component.height ?? 150,
      width: widget.component.width ?? double.infinity,
      child: Signature(
        controller: logic.signatureController,
        height: widget.component.height ?? 150,
        width: widget.component.width ?? double.infinity,
        backgroundColor: Colors.white,
      ),
    );
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.getValue(widget.component.key);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DataSourceStateBuilder(
        logic: logic,
        component: widget.component,
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorText: widget.controller.errors[widget.component.key],
                ),
                child: Stack(
                  children: [
                    _isExternalImage(value)
                        ? _buildExternalImage(value.toString())
                        : _buildSignatureCanvas(),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: widget.component.disabled
                            ? null
                            : logic.clearSignature,
                        tooltip: 'Clear Signature',
                      ),
                    ),
                  ],
                ),
              ),
              _buildDescription(),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  Widget _buildDescription() {
    if (widget.component.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        widget.component.description,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
