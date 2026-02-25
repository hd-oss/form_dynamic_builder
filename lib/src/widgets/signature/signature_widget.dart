import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
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
                child: Container(
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
