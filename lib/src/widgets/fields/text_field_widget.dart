import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../controller/form_controller.dart';
import '../../models/form_component.dart';
import '../../utils/form_constants.dart';
import 'field_label.dart';

class DynamicTextField extends StatefulWidget {
  final FormComponent component;
  final FormController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;

  const DynamicTextField({
    super.key,
    required this.component,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<DynamicTextField> createState() => _DynamicTextFieldState();
}

class _DynamicTextFieldState extends State<DynamicTextField> {
  late bool _obscureText;
  MaskTextInputFormatter? _maskFormatter;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;

    if (widget.component.inputMask.isNotEmpty) {
      _maskFormatter = MaskTextInputFormatter(
        mask: widget.component.inputMask,
        filter: {
          FormConstants.maskDigit: RegExp(r'[0-9]'),
          FormConstants.maskAlpha: RegExp(r'[a-zA-Z]'),
          FormConstants.maskAlphaNum: RegExp(r'[a-zA-Z0-9]'),
        },
        type: MaskAutoCompletionType.lazy,
      );
    }

    // Initialize text controller with current value from FormController
    final currentValue =
        widget.controller.getValue(widget.component.key)?.toString() ?? '';
    if (_maskFormatter != null && currentValue.isNotEmpty) {
      _maskFormatter!.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: currentValue),
      );
      _textController =
          TextEditingController(text: _maskFormatter!.getMaskedText());
    } else {
      _textController = TextEditingController(text: currentValue);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
              TextFormField(
                focusNode: widget.controller.getFocusNode(widget.component.key),
                controller: _textController,
                decoration: InputDecoration(
                  hintText: widget.component.placeholder,
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                  suffixIcon: _buildSuffixIcon(),
                ),
                obscureText: _obscureText,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                enabled: !widget.component.disabled,
                inputFormatters: [
                  if (widget.component.inputMask.isNotEmpty &&
                      _maskFormatter != null)
                    _maskFormatter!,
                  if (widget.component.textTransform ==
                      FormConstants.transformUppercase)
                    _UpperCaseTextFormatter(),
                  if (widget.component.textTransform ==
                      FormConstants.transformLowercase)
                    _LowerCaseTextFormatter(),
                  if (widget.component.type == FormConstants.typeNumber ||
                      widget.component.type == FormConstants.typeCurrency)
                    FilteringTextInputFormatter.allow(
                        RegExp(FormConstants.numericFilterPattern)),
                ],
                onChanged: (value) {
                  dynamic valueToStore = value;
                  if (widget.component.inputMask.isNotEmpty &&
                      _maskFormatter != null) {
                    valueToStore = _maskFormatter!.getUnmaskedText();
                  }
                  widget.controller
                      .updateValue(widget.component.key, valueToStore);
                },
                validator: (value) {
                  return null;
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (!widget.obscureText) return null;

    return IconButton(
      icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _obscureText = !_obscureText),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
