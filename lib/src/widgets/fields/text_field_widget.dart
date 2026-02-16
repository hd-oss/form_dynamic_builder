import 'package:flutter/material.dart';
import '../../controller/form_controller.dart';
import '../../models/form_component.dart';

class DynamicTextField extends StatefulWidget {
  final FormComponent component;
  final FormController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;

  const DynamicTextField({
    Key? key,
    required this.component,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  _DynamicTextFieldState createState() => _DynamicTextFieldState();
}

class _DynamicTextFieldState extends State<DynamicTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return TextFormField(
            initialValue:
                widget.controller.getValue(widget.component.key)?.toString(),
            decoration: InputDecoration(
              labelText: widget.component.label +
                  (widget.component.required ? ' *' : ''),
              hintText: widget.component.placeholder,
              border: OutlineInputBorder(),
              errorText: widget.controller.errors[widget.component.key],
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(_obscureText
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            enabled: !widget.component.disabled,
            onChanged: (value) {
              widget.controller.updateValue(widget.component.key, value);
            },
            validator: (value) {
              // Validation is handled in controller, but we can also add field-level if needed
              // The controller.validate() updates the error map which is shown in errorText
              return null;
            },
          );
        },
      ),
    );
  }
}
