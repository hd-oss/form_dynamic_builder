import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/form_controller.dart';
import '../../models/form_component.dart';
import '../../utils/form_constants.dart';
import '../field_label.dart';
import '../../services/mixins/data_source_mixin.dart';
import 'text_field_logic.dart';

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
  late final TextFieldLogic logic;

  @override
  void initState() {
    super.initState();
    logic = TextFieldLogic(
      component: widget.component,
      formController: widget.controller,
      initialObscureText: widget.obscureText,
    );
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  Widget? _buildSuffixIcon() {
    if (!widget.obscureText) return null;

    return IconButton(
      icon: Icon(logic.obscureText ? Icons.visibility : Icons.visibility_off),
      onPressed: logic.toggleObscureText,
    );
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
              if (logic.dsState == DataSourceState.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (logic.dsState == DataSourceState.error)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Failed to load data',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13),
                  ),
                )
              else
                TextFormField(
                  focusNode:
                      widget.controller.getFocusNode(widget.component.key),
                  controller: logic.textController,
                  decoration: InputDecoration(
                    hintText: widget.component.placeholder,
                    border: const OutlineInputBorder(),
                    errorText: widget.controller.errors[widget.component.key],
                    prefixText: logic.getPrefixText(),
                    suffixIcon: _buildSuffixIcon(),
                  ),
                  obscureText: logic.obscureText,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  enabled: !widget.component.disabled,
                  inputFormatters: [
                    if (widget.component.inputMask.isNotEmpty &&
                        logic.maskFormatter != null)
                      logic.maskFormatter!,
                    if (widget.component.textTransform ==
                        FormConstants.transformUppercase)
                      UpperCaseTextFormatter(),
                    if (widget.component.textTransform ==
                        FormConstants.transformLowercase)
                      LowerCaseTextFormatter(),
                    if (widget.component.type == FormConstants.typeNumber ||
                        widget.component.type == FormConstants.typeCurrency)
                      FilteringTextInputFormatter.allow(
                          RegExp(FormConstants.numericFilterPattern)),
                    if (logic.currencyFormatter != null)
                      logic.currencyFormatter!,
                  ],
                  onChanged: logic.onChanged,
                ),
            ],
          );
        },
      ),
    );
  }
}
