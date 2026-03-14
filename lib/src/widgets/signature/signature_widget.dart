import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/file_data.dart';
import '../../services/mixins/upload_mixin.dart';
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

  Widget _buildExternalImage(FileData? value) {
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
          Positioned.fill(
              child: logic.buildImageFromValue(context, value,
                  height: widget.component.height,
                  width: widget.component.width)),
          if (widget.component.disabled)
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
        ],
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
          final value = widget.controller.getValue(widget.component.key);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorText: widget.controller.errors[widget.component.key],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (logic.uploadStatus == UploadStatus.error)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                logic.uploadError ?? 'Upload failed',
                                style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (logic.uploadStatus == UploadStatus.uploading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(
                              strokeWidth: 4),
                        ),
                      )
                    else
                      Stack(
                        children: [
                          logic.isExternalImage(
                                  value is FileData ? value : null)
                              ? _buildExternalImage(value)
                              : _buildSignatureCanvas(),
                          if (value is FileData && value.isUploaded)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_done,
                                    color: Colors.green, size: 24),
                              ),
                            ),
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
