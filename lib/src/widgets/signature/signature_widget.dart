import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import '../../services/mixins/data_source_mixin.dart';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
          final value = widget.controller.getValue(widget.component.key);
          final bool isExternalImage = value != null &&
              value is String &&
              value.isNotEmpty &&
              logic.signatureController.isEmpty;

          Widget buildImageOrCanvas() {
            if (logic.dsState == DataSourceState.loading) {
              return SizedBox(
                height: widget.component.height ?? 150,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            if (logic.dsState == DataSourceState.error) {
              return SizedBox(
                height: widget.component.height ?? 150,
                child: Center(
                  child: Text(
                    'Failed to load data',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            if (isExternalImage) {
              final valStr = value.toString();
              Widget imageWidget;
              try {
                if (valStr.startsWith('http://') ||
                    valStr.startsWith('https://')) {
                  imageWidget = Image.network(
                    valStr,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  );
                } else if (valStr.contains(',')) {
                  // handle data:image/png;base64,...
                  final base64Str = valStr.split(',').last;
                  imageWidget = Image.memory(
                    base64Decode(base64Str),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  );
                } else if (RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(valStr)) {
                  imageWidget = Image.memory(
                    base64Decode(valStr),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  );
                } else {
                  // Fallback to file or generic error
                  imageWidget = const Center(child: Icon(Icons.broken_image));
                }
              } catch (e) {
                imageWidget = const Center(child: Icon(Icons.broken_image));
              }

              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                height: widget.component.height ?? 150,
                width: widget.component.width ?? double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    if (widget.component.disabled)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              );
            }

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
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
                        widget.component.disabled ? null : logic.clearSignature,
                    tooltip: 'Clear Signature',
                  ),
                ),
                child: buildImageOrCanvas(),
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
