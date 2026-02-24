import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'checkbox_logic.dart';

class DynamicCheckbox extends StatefulWidget {
  final CheckboxComponent component;
  final FormController controller;

  const DynamicCheckbox({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicCheckbox> createState() => _DynamicCheckboxState();
}

class _DynamicCheckboxState extends State<DynamicCheckbox> {
  late final CheckboxLogic logic;

  @override
  void initState() {
    super.initState();
    logic = CheckboxLogic(widget.component, widget.controller);
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
                  border: InputBorder.none,
                  errorText: widget.controller.errors[widget.component.key],
                ),
                child: CheckboxListTile.adaptive(
                  title: Text(widget.component.label),
                  value: logic.value,
                  onChanged: logic.onChanged,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
